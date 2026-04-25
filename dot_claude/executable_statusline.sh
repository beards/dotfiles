#!/usr/bin/env bash
# Custom Claude Code status line.
# Reads session JSON from stdin and prints one or more lines to stdout.
# Docs: https://code.claude.com/docs/zh-TW/statusline

set -u

# Walk up to 8 process ancestors looking for one that owns a real TTY,
# then read its size. Mirrors ccstatusline's probeTerminalWidth().
detect_terminal_width() {
    case "$(uname -s)" in MINGW*|MSYS*) return 1 ;; esac
    local pid=$$ ppid tty width
    for _ in 1 2 3 4 5 6 7 8; do
        ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        case "$ppid" in ''|0|1) break ;; esac
        pid=$ppid
        tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
        case "$tty" in ''|'?'|'??') continue ;; esac
        width=$(stty size < "/dev/$tty" 2>/dev/null | awk '{print $2}')
        if [ -n "${width:-}" ] && [ "$width" -gt 0 ] 2>/dev/null; then
            printf '%s' "$width"
            return 0
        fi
    done
    width=$(tput cols 2>/dev/null || true)
    if [ -n "${width:-}" ] && [ "$width" -gt 0 ] 2>/dev/null; then
        printf '%s' "$width"
        return 0
    fi
    return 1
}

# Reserved chars on the right for Claude Code's own notifications
# (auto-compact warnings, MCP errors, etc.). Scaled by terminal width so narrow
# windows can still show useful content; wider windows reserve up to 40 like
# ccstatusline does.
reserved_for_width() {
    local w=$1 r
    if [ "$w" -le 100 ]; then
        r=4
    elif [ "$w" -le 140 ]; then
        r=$(( w - 100 ))
        [ "$r" -lt 4 ] && r=4
    else
        r=40
    fi
    printf '%d' "$r"
}

ELLIPSIS='...'
SEP=' '

# ANSI colors. Width math always uses plain text; output uses these wrappers.
RESET=$'\e[0m'
GRAY=$'\e[90m'
WHITE=$'\e[37m'
BWHITE=$'\e[97m'
GREEN=$'\e[32m'
LYELLOW=$'\e[93m'
LRED=$'\e[91m'
YELLOW=$'\e[33m'
MAGENTA=$'\e[35m'
BBLUE=$'\e[94m'
GRAY_PIPE="${GRAY} | ${RESET}"
GRAY_SLASH="${GRAY} / ${RESET}"

# Pick a color for a percentage using the shared threshold scale:
# <50 green, 50-80 light yellow, >=80 light red.
pick_threshold_color() {
    local class
    class=$(awk -v p="${1:-0}" 'BEGIN {
        if (p < 50)      print "G"
        else if (p < 80) print "Y"
        else             print "R"
    }')
    case "$class" in
        G) printf '%s' "$GREEN" ;;
        Y) printf '%s' "$LYELLOW" ;;
        *) printf '%s' "$LRED" ;;
    esac
}

# Convert ISO 8601 timestamp (e.g. 2026-04-25T12:34:56Z, with optional fractional
# seconds and offset) to epoch seconds. Plain integers are returned as-is.
iso_to_epoch() {
    local ts=$1 cleaned
    [ -z "$ts" ] && return 1
    if [[ "$ts" =~ ^[0-9]+$ ]]; then
        printf '%d' "$ts"
        return 0
    fi
    cleaned=$(printf '%s' "$ts" | sed -E 's/\.[0-9]+Z$/Z/; s/\.[0-9]+([+-][0-9:]+)$/\1/')
    if [[ "$cleaned" == *Z ]]; then
        date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$cleaned" +%s 2>/dev/null && return 0
    fi
    cleaned=$(printf '%s' "$cleaned" | sed -E 's/([+-][0-9]{2}):([0-9]{2})$/\1\2/')
    date -j -f "%Y-%m-%dT%H:%M:%S%z" "$cleaned" +%s 2>/dev/null
}

# Format integer seconds as HH:mm:ss; clamps negative to 00:00:00.
sec_to_hms() {
    local s=${1:-0}
    [ "$s" -lt 0 ] 2>/dev/null && s=0
    printf '%02d:%02d:%02d' $(( s / 3600 )) $(( s % 3600 / 60 )) $(( s % 60 ))
}

# Format milliseconds as HH:mm:ss.
ms_to_hms() {
    local ms=${1:-0}
    sec_to_hms $(( ms / 1000 ))
}

# Greedy wrap of parts joined by sep across multiple lines, breaking from the
# right one separator at a time until the first line fits in max_width.
# Output: each resulting line on its own stdout line. If even a single part is
# too wide, it is printed as-is (caller doesn't worry about that case).
# Args: max_width sep part1 part2 ...
wrap_by_sep() {
    local max=$1 sep=$2
    shift 2
    local -a parts=("$@")
    local n=${#parts[@]}
    [ "$n" -eq 0 ] && return
    local k j first chosen_k=$((n - 1))
    for ((k = 0; k < n; k++)); do
        first=""
        for ((j = 0; j < n - k; j++)); do
            [ $j -gt 0 ] && first+="$sep"
            first+="${parts[j]}"
        done
        if [ "${#first}" -le "$max" ]; then
            chosen_k=$k
            break
        fi
    done
    first=""
    for ((j = 0; j < n - chosen_k; j++)); do
        [ $j -gt 0 ] && first+="$sep"
        first+="${parts[j]}"
    done
    printf '%s\n' "$first"
    for ((j = n - chosen_k; j < n; j++)); do
        printf '%s\n' "${parts[j]}"
    done
}

input=$(cat)

session_id=$(jq -r       '.session_id // empty'           <<<"$input")
current_dir=$(jq -r      '.workspace.current_dir // empty' <<<"$input")
model_id=$(jq -r         '.model.id // empty'             <<<"$input")
model_display=$(jq -r    '.model.display_name // empty'   <<<"$input")
effort_level=$(jq -r     '.effort.level // empty'         <<<"$input")
thinking_enabled=$(jq -r '.thinking.enabled // false'     <<<"$input")
agent_name=$(jq -r       '.agent.name // empty'           <<<"$input")

# Short session id: piece before the first dash (UUIDs split into 8-char prefix).
session_id_short=${session_id%%-*}

branch=""
if [ -n "$current_dir" ]; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || true)
fi

# Detect terminal width once for both lines.
term_width=""
reserved=0
width_marker=""
if w=$(detect_terminal_width); then
    term_width=$w
    reserved=$(reserved_for_width "$term_width")
else
    width_marker=' [w=?]'
fi

# ─── line 1: (id) dir (branch) ───
prefix=""
[ -n "$session_id_short" ] && prefix+="($session_id_short)"

suffix_plain=""
suffix=""
if [ -n "$branch" ]; then
    suffix_plain=" ($branch)"
    suffix=" ${MAGENTA}($branch)${RESET}"
fi

display_dir=$current_dir
if [ -n "${HOME:-}" ] && [ -n "$current_dir" ]; then
    if [ "$current_dir" = "$HOME" ]; then
        display_dir='~'
    elif [ "${current_dir#"$HOME"/}" != "$current_dir" ]; then
        display_dir="~/${current_dir#"$HOME"/}"
    fi
fi

display_dir_visible=$display_dir
if [ -n "$term_width" ] && [ -n "$display_dir" ]; then
    budget=$(( term_width - reserved - ${#prefix} - ${#suffix_plain} - ${#SEP} ))
    if [ "${#display_dir}" -gt "$budget" ]; then
        keep=$(( budget - ${#ELLIPSIS} ))
        if [ "$keep" -gt 0 ]; then
            display_dir_visible="${ELLIPSIS}${display_dir: -keep}"
        else
            display_dir_visible=""
        fi
    fi
fi

dir_segment=""
[ -n "$display_dir_visible" ] && dir_segment="${SEP}${YELLOW}${display_dir_visible}${RESET}"

# ─── line 2: model (effort) | thinking: On/Off | agent: name ───
[ "$thinking_enabled" = "true" ] && thinking_state="On" || thinking_state="Off"
agent_display=${agent_name:--}

# mode: 0 = full labels, 1 = no labels, 2 = no labels + model display_name
build_line2_plain() {
    local mode=$1 model effort_part p2 p3
    case $mode in
        0|1) model=${model_id:-${model_display:--}} ;;
        2)   model=${model_display:-${model_id:--}} ;;
    esac
    effort_part=""
    [ -n "$effort_level" ] && effort_part=" ($effort_level)"
    case $mode in
        0)   p2="Thinking: $thinking_state"; p3="Agent: $agent_display" ;;
        1|2) p2="$thinking_state";           p3="$agent_display" ;;
    esac
    printf '%s%s | %s | %s' "$model" "$effort_part" "$p2" "$p3"
}

build_line2_colored() {
    local mode=$1 model effort_c p2 p3
    case $mode in
        0|1) model=${model_id:-${model_display:--}} ;;
        2)   model=${model_display:-${model_id:--}} ;;
    esac
    effort_c=""
    [ -n "$effort_level" ] && effort_c=" ${BBLUE}(${effort_level})${RESET}"
    case $mode in
        0)
            p2="${WHITE}Thinking:${RESET} ${GREEN}${thinking_state}${RESET}"
            p3="${WHITE}Agent:${RESET} ${GREEN}${agent_display}${RESET}"
            ;;
        1|2)
            p2="${GREEN}${thinking_state}${RESET}"
            p3="${GREEN}${agent_display}${RESET}"
            ;;
    esac
    printf '%s%s%s%s%s%s' "${BWHITE}${model}${RESET}" "$effort_c" "$GRAY_PIPE" "$p2" "$GRAY_PIPE" "$p3"
}

if [ -n "$term_width" ]; then
    line2_max=$(( term_width - reserved ))
    line2=""
    fitted=0
    for mode in 0 1 2; do
        plain=$(build_line2_plain "$mode")
        if [ "${#plain}" -le "$line2_max" ]; then
            line2=$(build_line2_colored "$mode")
            fitted=1
            break
        fi
    done
    if [ "$fitted" = 0 ]; then
        m2_model="${model_display:-${model_id:--}}"
        m2_effort=""
        m2_effort_c=""
        if [ -n "$effort_level" ]; then
            m2_effort=" ($effort_level)"
            m2_effort_c=" ${BBLUE}(${effort_level})${RESET}"
        fi
        plain_arr=("${m2_model}${m2_effort}" "$thinking_state" "$agent_display")
        color_arr=("${BWHITE}${m2_model}${RESET}${m2_effort_c}" "${GREEN}${thinking_state}${RESET}" "${GREEN}${agent_display}${RESET}")
        n=3
        chosen_k=$((n - 1))
        for ((k = 0; k < n; k++)); do
            first_p=""
            for ((j = 0; j < n - k; j++)); do
                [ $j -gt 0 ] && first_p+=" | "
                first_p+="${plain_arr[j]}"
            done
            if [ "${#first_p}" -le "$line2_max" ]; then
                chosen_k=$k
                break
            fi
        done
        first_c=""
        for ((j = 0; j < n - chosen_k; j++)); do
            [ $j -gt 0 ] && first_c+="$GRAY_PIPE"
            first_c+="${color_arr[j]}"
        done
        line2="$first_c"
        for ((j = n - chosen_k; j < n; j++)); do
            line2+=$'\n'"${color_arr[j]}"
        done
    fi
else
    line2=$(build_line2_colored 0)
fi

# ─── line 3: tokens (cached) | ctx% | 5h/7d limits | duration | $cost ───
input_tokens=$(jq -r   '.context_window.current_usage.input_tokens // 0'                <<<"$input")
output_tokens=$(jq -r  '.context_window.current_usage.output_tokens // 0'               <<<"$input")
cache_create=$(jq -r   '.context_window.current_usage.cache_creation_input_tokens // 0' <<<"$input")
cache_read=$(jq -r     '.context_window.current_usage.cache_read_input_tokens // 0'     <<<"$input")
ctx_pct=$(jq -r        '(.context_window.used_percentage // .context_window.usage_percentage // 0)' <<<"$input")
five_h_pct=$(jq -r     '.rate_limits.five_hour.used_percentage // 0'                    <<<"$input")
five_h_resets=$(jq -r  '.rate_limits.five_hour.resets_at // empty'                       <<<"$input")
seven_d_pct=$(jq -r    '.rate_limits.seven_day.used_percentage // 0'                    <<<"$input")
seven_d_resets=$(jq -r '.rate_limits.seven_day.resets_at // empty'                       <<<"$input")
duration_ms=$(jq -r    '.cost.total_duration_ms // 0'                                    <<<"$input")
cost_usd=$(jq -r       '.cost.total_cost_usd // 0'                                       <<<"$input")

now_epoch=$(date +%s)
five_h_cd='??:??:??'
if epoch=$(iso_to_epoch "$five_h_resets"); then
    five_h_cd=$(sec_to_hms $(( epoch - now_epoch )))
fi
seven_d_cd='??:??:??'
if epoch=$(iso_to_epoch "$seven_d_resets"); then
    seven_d_cd=$(sec_to_hms $(( epoch - now_epoch )))
fi
duration_hms=$(ms_to_hms "$duration_ms")

# Pre-format numbers (rounded percentages, fixed-precision cost).
ctx_pct_round=$(awk -v p="$ctx_pct"     'BEGIN { printf "%.0f", p }')
five_h_round=$(awk -v p="$five_h_pct"   'BEGIN { printf "%.0f", p }')
seven_d_round=$(awk -v p="$seven_d_pct" 'BEGIN { printf "%.0f", p }')
cost_round=$(awk -v c="$cost_usd"       'BEGIN { printf "%.4f", c }')

C_CTX=$(pick_threshold_color "$ctx_pct")
C_5H=$(pick_threshold_color "$five_h_pct")
C_7D=$(pick_threshold_color "$seven_d_pct")

# Plain parts (for width math).
l3_p1="Ctx: ${ctx_pct_round}%"
l3_p2="I/O: ${input_tokens}/${output_tokens} (Cached: ${cache_create}/${cache_read})"
l3_p3a="5h: ${five_h_round}% (-${five_h_cd})"
l3_p3b="7d: ${seven_d_round}% (-${seven_d_cd})"
l3_p3="$l3_p3a / $l3_p3b"
l3_p4=$duration_hms
l3_p5="\$${cost_round}"

# Colored parts (for output).
l3_p1_c="${WHITE}Ctx:${RESET} ${C_CTX}${ctx_pct_round}%${RESET}"
l3_p2_c="${WHITE}I/O:${RESET} ${WHITE}${input_tokens}/${output_tokens}${RESET} (${WHITE}Cached:${RESET} ${WHITE}${cache_create}/${cache_read}${RESET})"
l3_p3a_c="${WHITE}5h:${RESET} ${C_5H}${five_h_round}%${RESET} (${WHITE}-${five_h_cd}${RESET})"
l3_p3b_c="${WHITE}7d:${RESET} ${C_7D}${seven_d_round}%${RESET} (${WHITE}-${seven_d_cd}${RESET})"
l3_p3_c="${l3_p3a_c}${GRAY_SLASH}${l3_p3b_c}"
l3_p4_c="${WHITE}${duration_hms}${RESET}"
l3_p5_c="${WHITE}\$${cost_round}${RESET}"

if [ -n "$term_width" ]; then
    line3_max=$(( term_width - reserved ))
    parts_p=("$l3_p1" "$l3_p2" "$l3_p3" "$l3_p4" "$l3_p5")
    parts_c=("$l3_p1_c" "$l3_p2_c" "$l3_p3_c" "$l3_p4_c" "$l3_p5_c")
    n=5
    chosen_k=$((n - 1))
    for ((k = 0; k < n; k++)); do
        first_p=""
        for ((j = 0; j < n - k; j++)); do
            [ $j -gt 0 ] && first_p+=" | "
            first_p+="${parts_p[j]}"
        done
        if [ "${#first_p}" -le "$line3_max" ]; then
            chosen_k=$k
            break
        fi
    done
    first_c=""
    for ((j = 0; j < n - chosen_k; j++)); do
        [ $j -gt 0 ] && first_c+="$GRAY_PIPE"
        first_c+="${parts_c[j]}"
    done
    line3="$first_c"
    for ((j = n - chosen_k; j < n; j++)); do
        # If the 5h/7d combined is alone on this line and still too wide, split.
        if [ "$j" = 2 ] && [ "${#parts_p[2]}" -gt "$line3_max" ]; then
            line3+=$'\n'"$l3_p3a_c"
            line3+=$'\n'"$l3_p3b_c"
        else
            line3+=$'\n'"${parts_c[j]}"
        fi
    done
else
    line3="${l3_p1_c}${GRAY_PIPE}${l3_p2_c}${GRAY_PIPE}${l3_p3_c}${GRAY_PIPE}${l3_p4_c}${GRAY_PIPE}${l3_p5_c}"
fi

printf '%s%s%s%s\n' "$prefix" "$dir_segment" "$suffix" "$width_marker"
printf '%s\n'       "$line2"
printf '%s\n'       "$line3"

#!/usr/bin/env bash
# SessionStart hook: cache the Claude account display name + plan for the active
# config dir, so the (shared) status line can read it cheaply on every render.
#
# Respects CLAUDE_CONFIG_DIR: each config dir gets its own cache and reads its
# own .claude.json, so one shared script shows the right account per instance.
# Note the asymmetry — by default .claude.json sits at $HOME/.claude.json, but
# under CLAUDE_CONFIG_DIR it moves into that directory.
#
# Output: <config_dir>/.session-account.json
#   subscription -> {"name":"Simon","plan":"Team","org":"txOne 2nd PDG"}
#   no oauth     -> {"name":"","plan":"API","org":""}
set -u

command -v jq >/dev/null 2>&1 || exit 0

if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    config_dir="$CLAUDE_CONFIG_DIR"
    claude_json="$CLAUDE_CONFIG_DIR/.claude.json"
else
    config_dir="${HOME}/.claude"
    claude_json="${HOME}/.claude.json"
fi
out="$config_dir/.session-account.json"

name=$(jq -r     '.oauthAccount.displayName // empty'      "$claude_json" 2>/dev/null)
org=$(jq -r      '.oauthAccount.organizationType // empty' "$claude_json" 2>/dev/null)
org_name=$(jq -r '.oauthAccount.organizationName // empty' "$claude_json" 2>/dev/null)

if [ -n "$org" ]; then
    plan="${org#claude_}"   # claude_max -> max, claude_team -> team
    plan="$(printf '%s' "${plan:0:1}" | tr '[:lower:]' '[:upper:]')${plan:1}"  # -> Max / Team
else
    name=""
    plan="API"
    org_name=""
fi

# Personal accounts get an auto-named "<email>'s Organization" — no information
# there (the plan already identifies them), so only keep real org names.
case "$org_name" in *"'s Organization") org_name="" ;; esac

jq -n --arg name "$name" --arg plan "$plan" --arg org "$org_name" \
      '{name:$name, plan:$plan, org:$org}' >"$out"

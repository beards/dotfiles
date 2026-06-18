#!/usr/bin/env bash
#
# Self-check for the chezmoi-synced ~/.claude setup. Verifies the external
# dependencies the synced config relies on. Read-only except it prints the
# command to (re)start the headroom proxy when it's down — it does not mutate.
# Run after a fresh `chezmoi apply`, or whenever Claude Code behaves oddly.
set -u

ok=0; warn=0; bad=0
pass()   { printf '  \033[32m✓\033[0m %s\n' "$1"; ok=$((ok + 1)); }
warned() { printf '  \033[33m!\033[0m %s\n' "$1"; warn=$((warn + 1)); }
fail()   { printf '  \033[31m✗\033[0m %s\n' "$1"; bad=$((bad + 1)); }

base="http://127.0.0.1:8787"
label="com.simon.headroom-proxy"
uid="$(id -u)"

echo "== CLIs =="
for t in jq uv node npx gh chezmoi rtk claude headroom; do
  if command -v "$t" >/dev/null 2>&1; then
    pass "$t"
  else
    case "$t" in
      headroom)        fail "headroom missing — uv tool install --python 3.13 \"headroom-ai[all]\"" ;;
      claude)          fail "claude missing — brew install --cask claude-code" ;;
      rtk|jq|uv|node|gh) fail "$t missing — brew install $t" ;;
      *)               fail "$t missing" ;;
    esac
  fi
done

echo "== headroom proxy =="
if curl -fs -m2 "$base/livez" >/dev/null 2>&1; then
  pass "proxy healthy ($base)"
elif command -v headroom >/dev/null 2>&1; then
  warned "proxy down — launchctl kickstart -k gui/$uid/$label"
else
  warned "proxy unreachable and headroom not installed — cc falls back to the direct API"
fi
if launchctl print "gui/$uid/$label" >/dev/null 2>&1; then
  pass "launchd agent loaded"
else
  warned "launchd agent not loaded — launchctl bootstrap gui/$uid ~/Library/LaunchAgents/$label.plist"
fi

echo "== plugins =="
if command -v claude >/dev/null 2>&1; then
  if claude plugin list >/dev/null 2>&1; then
    pass "claude plugin list ok"
  else
    warned "claude plugin list failed — see SETUP.md (plugins)"
  fi
fi

echo "== sanity =="
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  warned "ANTHROPIC_API_KEY is set — may override the personal OAuth account (check ~/.rc.local)"
else
  pass "no ANTHROPIC_API_KEY override"
fi

echo
printf 'doctor: %d ok, %d warn, %d fail\n' "$ok" "$warn" "$bad"
[ "$bad" -eq 0 ]

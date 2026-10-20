#!/usr/bin/env bash
#
# Self-check for the chezmoi-synced ~/.claude setup. Verifies the external
# dependencies the synced config relies on. Read-only — it does not mutate.
# Run after a fresh `chezmoi apply`, or whenever Claude Code behaves oddly.
set -u

ok=0; warn=0; bad=0
pass()   { printf '  \033[32m✓\033[0m %s\n' "$1"; ok=$((ok + 1)); }
warned() { printf '  \033[33m!\033[0m %s\n' "$1"; warn=$((warn + 1)); }
fail()   { printf '  \033[31m✗\033[0m %s\n' "$1"; bad=$((bad + 1)); }

echo "== CLIs =="
for t in jq uv node npx gh chezmoi rtk claude; do
  if command -v "$t" >/dev/null 2>&1; then
    pass "$t"
  else
    case "$t" in
      claude)          fail "claude missing — brew install --cask claude-code@latest" ;;
      rtk|jq|uv|node|gh) fail "$t missing — brew install $t" ;;
      *)               fail "$t missing" ;;
    esac
  fi
done

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

#!/bin/bash
# Claude Code PreToolUse hook
# - In git repos: allow all, but block destructive git history operations
# - Outside git repos: allow reads, require confirmation for modifications

# Read JSON input from stdin
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
TOOL_INPUT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin).get('tool_input',{})))" 2>/dev/null)

decide() {
  local decision="$1"
  local reason="$2"
  python3 -c "
import json
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'PreToolUse',
    'permissionDecision': '$decision',
    'permissionDecisionReason': '$reason'
  }
}))
"
  exit 0
}

# Read-only tools — always allow
case "$TOOL_NAME" in
  Read|Glob|Grep|WebFetch|WebSearch)
    exit 0
    ;;
esac

# For Bash commands, extract the command string
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('command',''))" 2>/dev/null)

  # Destructive git operations — always block
  case "$CMD" in
    *"git push --force"*|*"git push -f "*|*"git reset --hard"*|*"git rebase"*|*"git filter-branch"*|*"git reflog expire"*)
      decide "deny" "Destructive git history operation blocked"
      ;;
  esac

  # Read-only commands — always allow
  case "$CMD" in
    "git status"*|"git log"*|"git diff"*|"git branch"*|"git show"*|"git remote"*|\
    "ls"*|"pwd"*|"which"*|"type "*|"echo"*|"cat"*|"head"*|"tail"*|\
    "find"*|"grep"*|"rg "*|"wc "*|"file "*|"stat "*|\
    "node --version"*|"npm list"*|"brew list"*|*"--version"*|*"--help"*)
      decide "allow" ""
      ;;
  esac
fi

# Check if we're inside a git repo
if git rev-parse --is-inside-work-tree &>/dev/null; then
  # In git repo — modifications are reversible, allow
  decide "allow" ""
else
  # Not in git repo — require confirmation for modifications
  decide "ask" "Not in a git repo — this change may not be easily reversible"
fi

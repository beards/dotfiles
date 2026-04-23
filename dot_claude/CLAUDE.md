# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code).

## Claude Code harness conventions

Configured in `~/.claude/settings.json`:

- **Auto mode is the default** (`permissions.defaultMode: "auto"`). The user expects Claude to proceed autonomously on reversible work and only stop for destructive or shared-system actions.
- **Destructive git is denied at the harness level.** `git push --force*`, `git push -f*`, and `git filter-branch*` are blocked by `permissions.deny`; `git reset --hard*` and `git rebase*` are soft-denied. Do not attempt to work around these — if an operation genuinely requires them, ask the user to run it.
- **Hook: `~/.claude/check-permission.sh`** runs on every Edit/Write/Bash/NotebookEdit. If it rejects a command, read its output and adjust rather than retrying.
- **Language: Traditional Chinese (正體中文)** for all user-facing text. Code, identifiers, and in-code comments stay in English.


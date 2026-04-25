# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code).

## Claude Code harness conventions

Configured in `~/.claude/settings.json`:

- **Auto mode is the default** (`permissions.defaultMode: "auto"`). The user expects Claude to proceed autonomously on reversible work and only stop for destructive or shared-system actions.
- **Destructive git is denied at the harness level.** `git push --force*`, `git push -f*`, and `git filter-branch*` are blocked by `permissions.deny`; `git reset --hard*` and `git rebase*` are soft-denied. Do not attempt to work around these — if an operation genuinely requires them, ask the user to run it.
- **Hook: `~/.claude/check-permission.sh`** runs on every Edit/Write/Bash/NotebookEdit. If it rejects a command, read its output and adjust rather than retrying.
- **Language: Traditional Chinese (正體中文)** for all user-facing text. Code, identifiers, and in-code comments stay in English.

## Answering "how do I X?" / solution requests

When the user asks how to do something, or asks for a solution to a problem, **do not rely on model knowledge alone**. Verify against the current world before answering:

- **Use tools or web search** to check whether a mature, established approach already exists. Model training data lags reality — assume your prior knowledge is stale until confirmed.
- **For specific tools, languages, libraries, SDKs, or APIs:** consult the official documentation (via `context7` MCP, official docs sites, or `--help`/`man`). Never guess flag names, API signatures, or config keys.
- **Present options ranked by viability**, not just one answer. For each option give: a short description, main pros/cons, and **a source link** (official docs, RFC, repo, well-known blog post). The user should be able to dig deeper or ask follow-ups from the citation alone.
- Keep each option brief — depth lives behind the link, not in the response.


# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code).

## Claude Code harness conventions

Configured in `~/.claude/settings.json`:

- **Auto mode is the default** (`permissions.defaultMode: "auto"`). The user expects Claude to proceed autonomously on reversible work and only stop for destructive or shared-system actions.
- **Destructive git is denied at the harness level.** `git push --force*`, `git push -f*`, and `git filter-branch*` are blocked by `permissions.deny`; `git reset --hard*` and `git rebase*` are soft-denied. Do not attempt to work around these — if an operation genuinely requires them, ask the user to run it.
- **Language:** Converse with the user in Traditional Chinese (正體中文). Everything *written to a file* is in English — not only code, identifiers, and comments, but also all documentation: specs, design docs, READMEs, and any markdown. Commit messages and PR descriptions are English too. The Chinese rule applies ONLY to chat replies, never to persisted artifacts.

## Answering "how do I X?" / solution requests

When the user asks how to do something, or asks for a solution to a problem, **do not rely on model knowledge alone**. Verify against the current world before answering:

- **Use tools or web search** to check whether a mature, established approach already exists. Model training data lags reality — assume your prior knowledge is stale until confirmed.
- **For specific tools, languages, libraries, SDKs, or APIs:** consult the official documentation (via `context7` MCP, official docs sites, or `--help`/`man`). Never guess flag names, API signatures, or config keys.
- **Present options ranked by viability**, not just one answer. For each option give: a short description, main pros/cons, and **a source link** (official docs, RFC, repo, well-known blog post). The user should be able to dig deeper or ask follow-ups from the citation alone.
- Keep each option brief — depth lives behind the link, not in the response.
- **When `WebFetch` returns empty or fails** on a page (SPA, JS-rendered, behind login, complex client routing), don't degrade to `WebSearch` guessing — invoke the `agent-browser` skill instead. `agent-browser open <url> && agent-browser snapshot -i` runs a real Chrome via CDP and reaches DOM that `WebFetch` can't. Falls back gracefully on machines where `agent-browser` isn't installed.

## Extracting content from webpages or documents

When the user asks you to fetch, read, or research a URL or document, return the **fully expanded** content the first time — don't stop at the rendered surface:

- **Truncated link previews are display-only.** X/Twitter, Bluesky, Mastodon, Discord, Slack render long URLs as `domain.com/path…` ellipsis text. The real URL lives in the `href`; pull it, don't paste the visible preview.
- **Resolve shortlinks** (`t.co`, `bit.ly`, `lnkd.in`) to their final destinations: `curl -sI -L -o /dev/null -w '%{url_effective}\n' <url>`.
- **If a fetched summary feels lossy** (you'd have to ask the user "want me to grab more?"), don't ask — re-fetch the raw body, or fall back to `agent-browser` for JS-rendered pages, and report the full version.

## Working on code

Four principles to prevent common LLM coding mistakes — prefer caution over speed, but apply judgment on trivial tasks:

- **Think before coding.** State your assumptions before writing code; if a request has multiple valid readings, list them instead of silently picking one. Push back on needless complexity, and stop to ask when something is genuinely unclear rather than guessing.
- **Simplicity first.** Write the minimum code that solves the stated problem — nothing speculative. No abstractions for single-use code, no unrequested config/flexibility, no error handling for cases that can't occur. If 200 lines could be 50, cut it. Self-check: would an experienced engineer call this needlessly complex?
- **Surgical changes.** Touch only what the request needs. Don't "improve" or refactor working code, comments, or formatting around your change; match the existing style even if you'd write it differently. Flag unrelated dead code rather than deleting it; only remove what your own change orphaned. Every changed line should map to the request.
- **Goal-driven execution.** Turn vague requests into verifiable criteria ("fix the bug" → "reproduce with a failing test, then make it pass") before implementing. For complex tasks, lay out a numbered plan with a verification step per phase, then loop until the criteria are met.


## claude-obsidian skills

Before invoking any `claude-obsidian` skill (`/save`, `/wiki`, `/wiki-ingest`, `/wiki-query`, `/wiki-lint`, `/autoresearch`, `/canvas`, `/wiki-fold`), read `~/.claude/claude-obsidian.md` for vault path resolution and fallback rules. Do NOT use `@claude-obsidian.md` import syntax — that defeats the purpose by inlining it back into context.

@RTK.md

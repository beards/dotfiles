# claude-obsidian wiki vault

The canonical Obsidian vault is **machine-local**; the global CLAUDE.md is synced across machines via chezmoi so the absolute path lives elsewhere.

**Vault path resolution order** (every `claude-obsidian` skill — `/save`, `/wiki`, `/wiki-ingest`, `/wiki-query`, `/wiki-lint`, `/autoresearch`, `/canvas`, `/wiki-fold` — applies this regardless of the current working directory):

1. `$CLAUDE_OBSIDIAN_VAULT` environment variable, if set.
2. The single absolute path written in `~/.claude/claude-obsidian-vault` (one line, no trailing newline required). This file is intentionally machine-local — exclude it from chezmoi via `.chezmoiignore`.
3. If neither exists: **ask the user** for the vault path and offer to write it to `~/.claude/claude-obsidian-vault`. Do not guess.

Once resolved, write into `<vault>/wiki/...`. If the resolved path is unreachable (iCloud sync hung, mount missing, directory deleted), surface the failure and stop — do NOT silently fall back to a local stub.

**Never** create or use any of these as a fallback vault on any machine:
- `~/wiki`
- `~/Documents/wiki`
- a `wiki/` folder inside the current working directory
- `~/.claude/plugins/cache/.../wiki/` (plugin cache, not a real vault — known failure mode from 2026-05-15)

Cross-references:
- Vault-local conventions live in `<vault>/CLAUDE.md` (especially the "Lint conventions" section).
- Per-project feedback memory lives under `~/.claude/projects/<machine-specific-slug>/memory/` and is also machine-local.

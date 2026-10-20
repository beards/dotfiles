# Claude Code — fresh-machine setup

This `~/.claude` config is synced by [chezmoi](https://chezmoi.io). It depends on
external tools that a bare machine won't have. This runbook installs them so the
synced config works. Most of it is automated by the dotfiles bootstrap; this doc
explains the moving parts and the two bootstrap orderings.

Run `~/.claude/doctor.sh` at any time to check what's missing.

## Dependency inventory

| Tool | Install | What breaks without it |
|------|---------|------------------------|
| `claude` | `brew install --cask claude-code@latest` | the CLI itself |
| `jq` | `brew install jq` (or system `/usr/bin/jq`) | `statusline.sh`, `account-info.sh` (degrade quietly) |
| `rtk` | `brew install rtk` (homebrew/core) | `PreToolUse` hook `rtk hook claude` fails on every Bash call |
| `uv` | `brew install uv` | `uv tool`-installed helpers (e.g. graphify) |
| `node` / `npx` | `brew install node` | MCP servers (context7, …) |
| `gh` | `brew install gh` | GitHub operations referenced in `CLAUDE.md` |
| `chezmoi` | `brew install chezmoi` (or the install one-liner) | can't sync this config |
| `agentsview` | `brew install agentsview` | the `agentsview-finding-history` skill (`agentsview skills install`) |
| `graphify` | `uv tool install graphifyy` | the `graphify` skill (`graphify install --platform claude`) |
| `agent-browser` | `npm i -g agent-browser` | the `agent-browser` skill is only a stub pointing at the CLI |

All of these are installed by the chezmoi bootstrap scripts:
`run_once_before_install-packages.sh.tmpl` for the base tools and
`run_onchange_after_install-claude-skills.sh.tmpl` for the skill-generating
tools (it also regenerates their skills). Plugins such as `answer-me-with-html`
are declared in `settings.json` and fetched by Claude Code itself.

## Bootstrap ordering

### Order B — chezmoi first (recommended)

```bash
# 1. install chezmoi (Homebrew, or the official one-liner)
brew install chezmoi
# 2. pull + apply the dotfiles — run_once scripts install everything above
chezmoi init --apply <your-dotfiles-repo>
# 3. open Claude Code
cc
# 4. optional sanity check
~/.claude/doctor.sh
```

No chicken-and-egg: every dependency is in place before Claude Code starts.

### Order A — Claude Code first

```bash
# 1. install + open Claude Code (works: no synced settings yet)
brew install --cask claude-code@latest && claude
# 2. from inside Claude Code, pull and apply the dotfiles
#    (install chezmoi first if needed)
chezmoi init --apply <your-dotfiles-repo>
# 3. the environment just changed (hooks, wrapper). Heal + verify:
~/.claude/doctor.sh
# 4. RESTART Claude Code so it picks up the new config, and relaunch via `cc`
```

After applying the dotfiles, the running session is using the pre-sync config —
restart it (and use `cc`) so the hooks take effect.

## Plugins

Marketplaces and enabled plugins live in `settings.json`
(`enabledPlugins`, `extraKnownMarketplaces`). Claude Code auto-installs enabled
plugins from known marketplaces on first launch. To set them up explicitly:

```bash
claude plugin marketplace add anthropics/claude-plugins-official   # built-in; usually already present
claude plugin marketplace add AgriciDaniel/claude-obsidian
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install <name>@<marketplace>     # e.g. superpowers@claude-plugins-official
claude plugin list                             # verify
```

**Known inconsistency:** `settings.json` enables `codex@openai-codex`, but the
`openai-codex` marketplace isn't registered and the plugin isn't installed. Either
register that marketplace or remove `codex@openai-codex` from `enabledPlugins`.

### Machine-local plugins (this machine only, never synced)

Some plugins only make sense on one host — a `directory`-source marketplace
pointing at a local repo, a `pluginConfigs` block with a host-specific `ssh_host`,
etc. These must **not** land in the synced `settings.json`, yet they still have to
end up in the rendered `~/.claude/settings.json`, because plugin enablement is read
**only** from there. (Verified: a user-level `~/.claude/settings.local.json` is
*ignored* for `enabledPlugins` — setting a plugin `true`/`false` there has no
effect, so that file is not an option for machine-local plugins.)

The split that makes this work:

- **Shared base** (synced): `.chezmoitemplates/claude-settings-base.json`
- **This machine's extras** (never synced): `~/.claude/settings.machine.json` —
  absent from the chezmoi source and listed in `.chezmoiignore`. The
  `dot_claude/modify_private_settings.json.tmpl` modify script deep-merges it over
  the base on `chezmoi apply` (requires `jq`). Keys managed by neither the base
  nor the machine file — state Claude Code writes itself, e.g. `model`,
  `modelSettings` — pass through untouched, so they never show as drift.

`settings.machine.json` uses the normal `settings.json` schema; include only the
keys this machine adds, e.g.:

```json
{
  "enabledPlugins": { "<name>@<marketplace>": true },
  "extraKnownMarketplaces": {
    "<marketplace>": { "source": { "source": "directory", "path": "/abs/path" } }
  },
  "pluginConfigs": { "<name>@<marketplace>": { "options": { "k": "v" } } }
}
```

To add one (deep-merge so existing entries survive):

```bash
f=~/.claude/settings.machine.json
[ -f "$f" ] || echo '{}' > "$f"
echo '{ "enabledPlugins": { "<name>@<marketplace>": true } }' \
  | jq -s '.[0] * .[1]' "$f" - > "$f.tmp" && mv "$f.tmp" "$f"
chezmoi diff  ~/.claude/settings.json   # confirm it appears, nothing shared dropped
chezmoi apply ~/.claude/settings.json
# then restart Claude Code — it auto-installs the enabled plugin from its marketplace
```

## Notes / caveats

- **`ANTHROPIC_API_KEY`** is set in `~/.rc.local` (not chezmoi-managed — keep it that
  way). If exported it can override the personal account's OAuth subscription; `doctor.sh`
  warns about it.
- The **txone** corporate account (`~/txone/.claude-txone`) is a separate config dir with
  a weekday warm-up launchd job; it's out of scope here.

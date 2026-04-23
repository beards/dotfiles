# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Targets macOS, Debian/Ubuntu, and RHEL/CentOS. Supports `personal` / `work` profiles and a `minimal` mode for old or restricted machines.

## What's in here

| Area | Files |
| --- | --- |
| Shell | `dot_bashrc`, `dot_zshrc`, `dot_zprofile.tmpl`, `dot_bash_aliases`, `dot_zsh/antigen.zsh` |
| Editor | `dot_vim/` (self-contained vimrc + Vundle-managed plugins), `symlink_dot_vimrc` |
| Terminal | `dot_tmux.conf.tmpl` (auto-adapts to tmux version), `dot_screenrc` |
| Git | `private_dot_config/git/` (`config.tmpl` + per-profile includes, `ignore`) |
| macOS | `private_dot_config/karabiner/` (only applied on darwin) |
| Claude Code | `dot_claude/` (settings + skills) |
| Scripts | `scripts/` (helpers on `$PATH` via `$HOME/scripts`) |
| Bootstrap | `run_once_before_install-packages.sh.tmpl`, `run_onchange_after_install-vim-plugins.sh.tmpl` |

Key chezmoi config:

- `.chezmoi.toml.tmpl` — prompts for `profile` (personal/work) and `minimal` (bool) on first init.
- `.chezmoiexternal.toml` — pulls [Vundle](https://github.com/gmarik/vundle) into `~/.vim/bundle/vundle`.
- `.chezmoiignore` — hides work-only git configs when `profile != work`, Karabiner on non-macOS, and all installers when `minimal` is true.

## Apply to a new machine

### 1. Install chezmoi

```sh
# macOS
brew install chezmoi

# Debian/Ubuntu
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# RHEL/CentOS (or any Linux)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

### 2. Init + apply

```sh
chezmoi init --apply https://github.com/beards/dotfiles.git
```

You will be prompted for:

- **profile** — `personal` or `work` (controls git identity includes).
- **minimal** — `true` on an old/locked-down box to skip Homebrew/apt installs, vim plugin install, and the Vundle clone. `false` on a normal dev machine.

On a full (non-minimal) run this will:

1. Write all dotfiles into `$HOME`.
2. Run `run_once_before_install-packages.sh` — installs git, vim, diff-so-fancy, autoenv, and (on macOS) Karabiner via Homebrew / apt / yum.
3. Clone Vundle into `~/.vim/bundle/vundle` via the external config.
4. Run `run_onchange_after_install-vim-plugins.sh` — executes `vim +BundleInstall +qall` (re-runs whenever `dot_vim/dot_vimrc_plugins` changes).

### 3. Post-install (manual)

- Set your login shell to zsh if you want the zsh setup: `chsh -s $(which zsh)`.
- Antigen bundles (oh-my-zsh, autosuggestions, theme `steeef`, etc.) will auto-install on first zsh launch.
- Machine-local overrides go in `~/.rc.local` — both `.bashrc` and `.zshrc` source it if present.
- On macOS, open Karabiner-Elements once to grant input-monitoring permission; the config under `~/.config/karabiner/` will already be in place.

### Minimal mode

Pick `minimal = true` when the machine is old, offline, or you lack sudo. It skips:

- `run_once_before_install-packages.sh` (no package installs)
- `run_onchange_after_install-vim-plugins.sh` (no `:BundleInstall`)
- Vundle external clone

You still get shell rc files, aliases, tmux/screen config, and vimrc — enough to feel at home without touching the system.

## Remote deploy from an already-configured machine

When you have a working machine and want to bootstrap a brand-new box over SSH without first installing chezmoi on the remote, use any of these in order of preference.

### How profile prompts are resolved (non-interactive)

`.chezmoi.toml.tmpl` resolves `profile` and `minimal` in this order:

1. **Env vars** `CHEZMOI_PROFILE` / `CHEZMOI_MINIMAL` — set these for fully non-interactive deploys.
2. **Existing config** — if `~/.config/chezmoi/chezmoi.toml` already has values (e.g. a re-apply), they are reused.
3. **Interactive prompt** — only when stdin is a real TTY (i.e. a normal local init).
4. **Silent default** — if none of the above apply (non-TTY, no env, no prior config), `profile` falls back to `"personal"` and `minimal` to `false`.

### Option A — `chezmoi ssh` + env vars (recommended)

`chezmoi ssh` connects to the remote, installs chezmoi, and runs `chezmoi init --apply`. Pass `CHEZMOI_PROFILE` / `CHEZMOI_MINIMAL` via the environment to pre-seed the prompts without needing a TTY.

> **Note:** `chezmoi ssh` does **not** allocate a pseudo-TTY, so interactive prompts will fail. Always supply the env vars below.

```sh
CHEZMOI_PROFILE=personal CHEZMOI_MINIMAL=false \
  chezmoi ssh user@newhost -- beards/dotfiles
```

Variants:

```sh
# Work machine
CHEZMOI_PROFILE=work CHEZMOI_MINIMAL=false \
  chezmoi ssh user@workbox -- beards/dotfiles

# Old / restricted box — skip package installs and vim plugin setup
CHEZMOI_PROFILE=personal CHEZMOI_MINIMAL=true \
  chezmoi ssh user@oldbox -- beards/dotfiles

# One-shot (don't leave chezmoi state on the remote after apply)
CHEZMOI_PROFILE=personal CHEZMOI_MINIMAL=false \
  chezmoi ssh user@throwaway -- --one-shot beards/dotfiles
```

Useful flags:

- `-p, --package-manager apt-get|brew|dnf|...` — force a specific installer on the remote; otherwise chezmoi falls back to `curl`/`wget`.
- `--one-shot` — apply and remove chezmoi state afterwards.
- `chezmoi ssh` is marked experimental in the docs — if it misbehaves, fall back to Option B.

### Option B — manual `ssh` (fallback)

If `chezmoi ssh` isn't available or fails, install chezmoi and init directly over SSH:

```sh
ssh user@newhost 'curl -fsSL https://get.chezmoi.io | sh -s -- -b ~/.local/bin && \
  CHEZMOI_PROFILE=personal CHEZMOI_MINIMAL=false ~/.local/bin/chezmoi init --apply beards/dotfiles'
```

For a work machine, use `CHEZMOI_PROFILE=work`. For a locked-down box, `CHEZMOI_MINIMAL=true`.

### Option C — push source tree directly (no GitHub access)

If the remote can't reach GitHub (air-gapped, behind a corporate proxy, etc.), copy the source repo over and point chezmoi at the local path:

```sh
# from your local machine
rsync -az --delete ~/.local/share/chezmoi/ user@newhost:/tmp/chezmoi-src/

ssh user@newhost 'sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin && \
  CHEZMOI_PROFILE=personal CHEZMOI_MINIMAL=false \
  ~/.local/bin/chezmoi init --apply --source=/tmp/chezmoi-src'
```

If even `curl | sh` is blocked, scp the chezmoi binary to `~/.local/bin/chezmoi` on the remote first, then run just the `chezmoi init --apply --source=...` line.

### Keeping the remote in sync later

Once the remote is bootstrapped, future updates are a one-liner from anywhere:

```sh
ssh user@newhost 'chezmoi update'     # git pull + apply
```

Or push local uncommitted tweaks for quick iteration:

```sh
rsync -az ~/.local/share/chezmoi/ user@newhost:.local/share/chezmoi/
ssh user@newhost 'chezmoi apply'
```

## Day-to-day

```sh
chezmoi edit <file>        # edit the source, then apply
chezmoi diff               # preview pending changes
chezmoi apply              # apply source -> $HOME
chezmoi update             # git pull + apply
chezmoi cd                 # jump into the source repo
```

The source repo lives at `~/.local/share/chezmoi/`.

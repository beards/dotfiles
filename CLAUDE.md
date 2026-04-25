# CLAUDE.md

This repo is the **chezmoi source directory** for personal dotfiles. Files
here are templates that get rendered into `$HOME` by `chezmoi apply`.

## Source-to-target mapping (chezmoi naming)

| Prefix / suffix | Effect on apply |
| --- | --- |
| `dot_foo` | `~/.foo` |
| `private_foo` | `~/foo` with mode `0600` (or `0700` for dirs) |
| `symlink_dot_foo` | `~/.foo` as a symlink (target is the file's content) |
| `*.tmpl` | Rendered as a Go template before writing |
| `run_once_before_*.sh.tmpl` | One-shot script run before apply (tracked by hash) |
| `run_onchange_after_*.sh.tmpl` | Runs after apply whenever its content changes |
| `executable_foo` | `~/foo` with `+x` |

Examples in this repo: `dot_bashrc` → `~/.bashrc`; `private_dot_config/git/` →
`~/.config/git/` (private); `symlink_dot_vimrc` → `~/.vimrc` symlinked to
`~/.vim/vimrc`.

## Edit → apply workflow

Edits to source files do **not** affect `$HOME` until applied:

```sh
chezmoi diff      # preview pending changes
chezmoi apply     # write source -> $HOME
```

When in doubt about whether the user wants a change applied immediately, ask.
Never run `chezmoi apply` for changes the user hasn't asked you to deploy.

## Template data

`.tmpl` files have access to (see `.chezmoi.toml.tmpl`):

- `.profile` — `"personal"` or `"work"` (selected at `chezmoi init`).
- `.minimal` — `true` on locked-down boxes; gates installer scripts.
- `.chezmoi.os` — `"darwin"`, `"linux"`, etc.

`.chezmoiignore` is itself a template and uses these to hide work-only git
configs, Karabiner on non-macOS, and installers in minimal mode.

## Conventions

- **Main branch is `master`** (not `main`).
- **No unit tests.** Verify changes with `chezmoi diff` before applying.
- **README.md is the user-facing doc** — keep examples runnable.
- When adding a new shell alias / function, edit `dot_bash_aliases` (sourced
  by both `dot_bashrc` and `dot_zshrc`).

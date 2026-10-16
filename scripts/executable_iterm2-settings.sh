#!/usr/bin/env bash
# Export / import iTerm2 settings (the com.googlecode.iterm2 defaults domain)
# as an XML plist so they can be versioned in chezmoi.
set -euo pipefail

DOMAIN=com.googlecode.iterm2
REL_PATH=iterm2/$DOMAIN.plist

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") export [PATH]        write current iTerm2 settings to PATH (XML plist)
  $(basename "$0") import [PATH] [-f]   load PATH into iTerm2 settings (-f: even while iTerm2 is running)

PATH defaults to the copy kept in the chezmoi source directory:
  \$(chezmoi source-path)/private_dot_config/$REL_PATH
Without chezmoi it falls back to ~/.config/$REL_PATH.

Export drops NoSync* keys (per-machine state that iTerm2 itself never syncs).
Import merges keys into the live settings; restart iTerm2 afterwards.
USAGE
  exit "${1:-0}"
}

default_path() {
  if command -v chezmoi >/dev/null 2>&1; then
    echo "$(chezmoi source-path)/private_dot_config/$REL_PATH"
  else
    echo "$HOME/.config/$REL_PATH"
  fi
}

cmd=${1:-}
[[ -z $cmd || $cmd == -h || $cmd == --help ]] && usage 0
shift
[[ $(uname -s) == Darwin ]] || { echo "error: macOS only" >&2; exit 1; }

force=0
path=""
for arg in "$@"; do
  case $arg in
    -f|--force) force=1 ;;
    -*) echo "error: unknown option: $arg" >&2; usage 1 ;;
    *) path=$arg ;;
  esac
done
path=${path:-$(default_path)}

case $cmd in
  export)
    mkdir -p "$(dirname "$path")"
    defaults export "$DOMAIN" - | python3 -I -c '
import plistlib, sys
d = plistlib.loads(sys.stdin.buffer.read())
d = {k: v for k, v in d.items() if not k.startswith("NoSync")}
plistlib.dump(d, sys.stdout.buffer, fmt=plistlib.FMT_XML, sort_keys=True)
' > "$path"
    echo "exported $DOMAIN -> $path"
    ;;
  import)
    [[ -f $path ]] || { echo "error: no such file: $path" >&2; exit 1; }
    if pgrep -xq iTerm2 && (( ! force )); then
      echo "error: iTerm2 is running and would overwrite the imported settings on quit." >&2
      echo "       Quit iTerm2 first, or pass -f to import anyway." >&2
      exit 1
    fi
    defaults import "$DOMAIN" "$path"
    echo "imported $path -> $DOMAIN (restart iTerm2 to pick up the changes)"
    ;;
  *)
    echo "error: unknown command: $cmd" >&2
    usage 1
    ;;
esac

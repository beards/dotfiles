#!/usr/bin/env bash

set -euo pipefail

pushd . &> /dev/null

SCRIPT_NAME=${BASH_SOURCE[0]}
DOTFILES_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_DIR=$DOTFILES_DIR/scripts

source $SCRIPT_DIR/util_funcs.sh

echo -e "#"
echo -e "# $SCRIPT_NAME: install necessary packages"
echo -e "#"

$SCRIPT_DIR/installer/install.sh package_manager
if [ $(get_platform) == "mac" ] && [ -f "$HOME/.zprofile" ] ; then
    source ~/.zprofile
fi
$SCRIPT_DIR/installer/install.sh git
$SCRIPT_DIR/installer/install.sh git_config
$SCRIPT_DIR/installer/install.sh stow

echo -e "#"
echo -e "# $SCRIPT_NAME: apply shell env"
echo -e "#"

cd $DOTFILES_DIR
stow bash --adopt -t ~
stow screen --adopt -t ~
stow zsh --adopt -t ~
stow tmux --adopt -t ~
stow git --adopt -t ~
stow links --adopt -t ~

$SCRIPT_DIR/installer/install.sh autoenv

if [ ! -z "`git status -s`" ]; then
    CUR_BRANCH=`git rev-parse --abbrev-ref HEAD`
    git checkout -b "stow-backup-$(date '+%Y-%m-%d')"
    git add -u
    git commit -m 'backup from stow --adopt'
    git checkout ${CUR_BRANCH}
fi

echo -e "#"
echo -e "# $SCRIPT_NAME: configure vim settings"
echo -e "#"

cd $DOTFILES_DIR
stow vim --adopt -t ~
$SCRIPT_DIR/installer/install.sh vim_plugin

echo -e "#"
echo -e "# $SCRIPT_NAME: done !"
echo -e "#"

popd &> /dev/null


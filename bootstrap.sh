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

exe $SCRIPT_DIR/installer/install.sh package_manager
echo ??
if [ $(get_platform) == "mac" ] && [ -f "$HOME/.zprofile" ] ; then
    source ~/.zprofile
fi

exe $SCRIPT_DIR/installer/install.sh git
exe $SCRIPT_DIR/installer/install.sh stow
exe $SCRIPT_DIR/installer/install.sh diff

echo -e "#"
echo -e "# $SCRIPT_NAME: apply shell env"
echo -e "#"

cd $DOTFILES_DIR
exe stow bash --adopt -t ~
exe stow screen --adopt -t ~
exe stow zsh --adopt -t ~
exe stow tmux --adopt -t ~
exe stow links --adopt -t ~

mkdir -p ~/.config/git > /dev/null 2>&1
exe stow git --adopt -t ~/.config/git

exe $SCRIPT_DIR/installer/install.sh autoenv

if [ ! -z "`git status -s`" ]; then
    CUR_BRANCH=`git rev-parse --abbrev-ref HEAD`
    git checkout -b "stow-backup-$(date '+%Y-%m-%d_%H%M%S')"
    git add -u
    git commit -m 'backup from stow --adopt'
    git checkout ${CUR_BRANCH}
fi

echo -e "#"
echo -e "# $SCRIPT_NAME: configure vim settings"
echo -e "#"

cd $DOTFILES_DIR
exe stow vim --adopt -t ~
exe $SCRIPT_DIR/installer/install.sh vim_plugin

echo -e "#"
echo -e "# $SCRIPT_NAME: done !"
echo -e "#"

popd &> /dev/null


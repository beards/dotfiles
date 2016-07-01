#!/bin/bash

set -e

pushd . &> /dev/null

SCRIPT_NAME=${BASH_SOURCE[0]}
DOTFILES_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_DIR=$DOTFILES_DIR/scripts/

echo -e "#"
echo -e "# $SCRIPT_NAME: install necessary packages"
echo -e "#"

$SCRIPT_DIR/installer/install.sh package_manager
$SCRIPT_DIR/installer/install.sh stow

echo -e "#"
echo -e "# $SCRIPT_NAME: apply shell env"
echo -e "#"

if [ ! -e ~/.oh-my-zsh ]; then
    git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
else
    cd ~/.oh-my-zsh
    git pull --rebase
fi

cd $DOTFILES_DIR
stow zsh -t ~
stow tmux -t ~
stow autoenv -t ~
stow links -t ~

$SCRIPT_DIR/installer/install.sh git_config

stow bash -t ~
stow screen -t ~

echo -e "#"
echo -e "# $SCRIPT_NAME: configure vim settings"
echo -e "#"

cd $DOTFILES_DIR
stow vim -t ~
$SCRIPT_DIR/installer/install.sh vim_plugin

echo -e "#"
echo -e "# $SCRIPT_NAME: done !"
echo -e "#"

popd &> /dev/null


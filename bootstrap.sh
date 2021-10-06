#!/usr/bin/env bash

set -e

pushd . &> /dev/null

SCRIPT_NAME=${BASH_SOURCE[0]}
DOTFILES_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_DIR=$DOTFILES_DIR/scripts

echo -e "#"
echo -e "# $SCRIPT_NAME: install necessary packages"
echo -e "#"

$SCRIPT_DIR/installer/install.sh package_manager
$SCRIPT_DIR/installer/install.sh stow

echo -e "#"
echo -e "# $SCRIPT_NAME: apply shell env"
echo -e "#"

OH_MY_ZSH_DIR=~/.oh-my-zsh
if [ ! -e $OH_MY_ZSH_DIR ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git $OH_MY_ZSH_DIR
else
    cd $OH_MY_ZSH_DIR
    git pull --rebase
fi

ZSH_AUTOSUGG_DIR=$OH_MY_ZSH_DIR/custom/plugins/zsh-autosuggestions
if [ ! -e $ZSH_AUTOSUGG_DIR ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_AUTOSUGG_DIR
else
    cd $ZSH_AUTOSUGG_DIR
    git pull --rebase
fi

cd $DOTFILES_DIR
stow bash --adopt -t ~
stow screen --adopt -t ~
stow zsh --adopt -t ~
stow tmux --adopt -t ~
stow links --adopt -t ~

$SCRIPT_DIR/installer/install.sh autoenv

if [ ! -z "`git status -s`" ]; then
    CUR_BRANCH=`git rev-parse --abbrev-ref HEAD`
    git checkout -b "stow-backup-`date -I`"
    git add -u
    git commit -m 'backup from stow --adopt'
    git checkout ${CUR_BRANCH}
fi

$SCRIPT_DIR/installer/install.sh git_config

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


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

if [ ! -e ~/.oh-my-zsh ]; then
    git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
else
    cd ~/.oh-my-zsh
    git pull --rebase
fi

cd $DOTFILES_DIR
stow zsh --adopt -t ~
stow tmux --adopt -t ~
stow autoenv --adopt -t ~
stow links --adopt -t ~

$SCRIPT_DIR/installer/install.sh git_config

stow bash --adopt -t ~
stow screen --adopt -t ~

if [ ! -z "`git status -s`" ]; then
    CUR_BRANCH=`git rev-parse --abbrev-ref HEAD`
    git checkout -b "stow-backup-`date -I`"
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


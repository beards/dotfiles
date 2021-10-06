# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
elif [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

source $HOME/scripts/util_funcs.sh

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
#if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
#    . /etc/bash_completion
#fi

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# disable ctrl-s
stty -ixon

# prompt

PS1='${debian_chroot:+($debian_chroot)}\[\033[;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"

[ "$TERM" = "xterm" ] && TERM="xterm-256color"

case $TERM in
 xterm*|rxvt*)
  PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}[${PWD/$HOME/~}]\007"'
 ;;
 screen*)
  PROMPT_COMMAND='echo -ne "\033k[${USER}@`hostname -s` `basename ${PWD}`]\033\0134"'
 ;;
 *)
 ;;
esac

# local & encoding
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# path
pathprepend /usr/local/sbin /usr/local/bin

# autoenv
if [ -f ~/.autoenv/activate.sh ]; then
    source ~/.autoenv/activate.sh
fi

# pyenv
if [ -e $HOME/.pyenv ]; then
    export PYENV_ROOT="$HOME/.pyenv"
elif [ -e /usr/local/opt/pyenv ]; then
    export PYENV_ROOT="/usr/local/opt/pyenv"
fi
if [ $PYENV_ROOT ]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# mac bash completion
OS=$(get_platform)
if [ $OS == "mac" ]; then
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
        . $(brew --prefix)/etc/bash_completion
    fi
fi

# User specific aliases and functions
source ~/.bash_aliases


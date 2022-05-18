# 256 colors
export TERM=xterm-256color

# enable HOME/END key with xterm
bindkey "\033[1~" beginning-of-line
bindkey "\033[4~" end-of-line

# set language environment
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# disable ctrl-s
stty -ixon

# Do not resolve * by zsh
setopt no_nomatch

# Tells 'less' not to paginate if less than a page,
# and use raw control chars to accept colored contents
export LESS="-R -F -X $LESS"

# set path
source $HOME/scripts/util_funcs.sh
pathprepend /usr/local/sbin /usr/local/bin

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT" ]; then
    pathprepend $PYENV_ROOT/bin
    eval "$(pyenv init --path)"
fi

# use antigen to manage zsh plugins and themes
source ~/.zsh/antigen.zsh
antigen use oh-my-zsh
antigen bundle git
antigen bundle zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle autoenv
antigen bundle pyenv
antigen bundle MikeDacre/tmux-zsh-vim-titles
antigen theme steeef
antigen apply

DISABLE_AUTO_TITLE=false

# alias
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

source ~/.profile


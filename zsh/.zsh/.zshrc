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

# Tells 'less' not to paginate if less than a page
export LESS="-F -X $LESS"

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
OS=$(get_platform)
if [ "$OS" = "debian" ]; then
    alias ls='ls --color=auto'
    alias l='ls --color=auto -l'
    alias ll='ls --color=auto -la'
    alias la='ls --color=auto -a'
elif [ "$OS" = "mac" ]; then
    alias ls='ls -vG'
    alias l='ls -vG -l'
    alias ll='ls -vG -la'
    alias la='ls -vG -a'

    alias cdsim='cd ~/Library/Application\ Support/iPhone\ Simulator/'
fi

alias tm='tmux new -ADs'
alias tml='tmux list-sessions'
alias 0='tmux new -ADs 0'

alias vi='vim'

alias g='git'
alias gs='git status'
alias gdc='git diff --cached'
alias gl='git log --pretty=format:"%Cgreen%h %Cblue%cn %Cred(%cd)%Creset:%n    %Cgreen%s%Creset" --name-status'
alias gl1='git log --pretty=format:"%Cgreen%h %Cblue%an %Cred(%cd)%Creset: %s"'
alias glg='git log --graph --abbrev-commit --decorate --date=relative --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)" --all'

alias d='docker'
alias dc='docker container'
alias di='docker image'
alias dx='docker exec -it'

alias cdc='cd $HOME/_code/'
alias cdgit='cd $HOME/github'

source ~/.profile


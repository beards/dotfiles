source $HOME/scripts/util_funcs.sh

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
alias ga='git add'
alias gs='git status'
alias gf='git fetch'
alias gdc='git diff --cached'
alias gl='git log --pretty=format:"%Cgreen%h %Cblue%cn %Cred(%cd)%Creset:%n    %Cgreen%s%Creset" --name-status'
alias gl1='git log --pretty=format:"%Cgreen%h %Cblue%cn %Cred(%cd)%Creset: %s"'
alias glg='git log --graph --abbrev-commit --decorate --date=relative --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)" --all'

alias d='docker'
alias dc='docker container'
alias di='docker image'
alias dx='docker exec -it'

alias cdc='cd $HOME/_code/'
alias cdgit='cd $HOME/github'


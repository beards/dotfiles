source $HOME/scripts/util_funcs.sh

OS=$(get_platform)
if [ "$OS" = "debian" ]; then
    alias ls='ls --color=auto'
    alias l='ls --color=auto -l'
    alias ll='ls --color=auto -la'
    alias la='ls --color=auto -a'

    alias vi='vim'
elif [ "$OS" = "mac" ]; then
    alias ls='ls -vG'
    alias l='ls -vG -l'
    alias ll='ls -vG -la'
    alias la='ls -vG -a'

    alias vi='mvim -v'
fi

alias diff='diff --color=always'
alias grep='grep --color=always'
alias ack='ack --color --pager="less -R"'

alias tm='tmux new -ADs'
alias tml='tmux list-sessions'
alias 0='tmux new -ADs 0'

alias g='git'
alias ga='git add'
alias gs='git status'
alias gf='git fetch'
alias gdc='git diff --cached'
#alias gl='git log --pretty=format:"%Cgreen%h %Cblue%cn %Cred(%cd)%Creset:%n    %Cgreen%s%Creset" --name-status'
alias gl='git log --pretty=format:"%Cgreen%h %Cblue%cn %Cred(%cd)%Creset: %C(bold yellow)%d%C(reset)%n    %Cgreen%s%Creset" --name-status'
alias gl1='git log --pretty=format:"%Cgreen%h %Cblue%an %Cred(%ci)%Creset: %s %C(bold yellow)%d%C(reset)"'
alias glg='git log --graph --abbrev-commit --decorate --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%as)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)" --all'

alias d='docker'
alias dc='docker container'
alias di='docker image'
alias dx='docker exec -it'
alias dr='docker run -it --rm'

alias cdc='cd $HOME/_code/'
alias cdgit='cd $HOME/github'


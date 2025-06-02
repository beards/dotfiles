#!/usr/bin/env bash

lowercase() {
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

get_platform() {
    local OS=`lowercase \`uname\``
    if [ "$OS" = "windowsnt" ]; then
        OS=windows
    elif [ "$OS" = "darwin" ]; then
        OS=mac
    elif [ -f /etc/redhat-release ]; then
        OS=redhat
    elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
        OS=debian
    fi

    echo $OS
}

pathappend() {
    for ARG in "$@"
    do
        if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
            export PATH="${PATH:+"$PATH:"}$ARG"
        fi
    done
}

pathprepend() {
    for ((i=$#; i>0; i--));
    do
        ARG=${@:$i:1}
        if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
            export PATH="$ARG${PATH:+":$PATH"}"
        fi
    done
}

add_config_line() {
    LINE=$1
    FILE=$2
    grep -sxqF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"
}

_exe(){
    [ $1 == on  ] && { set -x; return; } 2>/dev/null
    [ $1 == off ] && { set +x; return; } 2>/dev/null
    echo + "$@"
    "$@"
}
exe(){
    { _exe "$@"; } 2>/dev/null
}


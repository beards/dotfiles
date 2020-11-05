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


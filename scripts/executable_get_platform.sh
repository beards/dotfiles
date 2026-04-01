#!/usr/bin/env bash

lowercase() {
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

OS=`lowercase \`uname\``
if [ "$OS" = "windowsnt" ]; then
    OS=windows
elif [ "$OS" = "darwin" ]; then
    OS=mac
elif [ -f /etc/redhat-release ]; then
    OS=redhat
elif [ -f /etc/lsb-release ]; then
    OS=debian
fi

export $OS


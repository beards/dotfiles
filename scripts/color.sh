#!/usr/bin/env bash

if [ -z $1 ]; then
    BREAK=8
else
    BREAK=$1
fi
BREAK2=$((BREAK / 2))
echo $BREAK2

for i in {0..255} ; do
    printf "\x1b[38;5;${i}mcolour${i} \t"
    if [ $(( i % $BREAK )) -eq $(($BREAK-1)) ] ; then
        printf "\n"
    fi
done
printf "\n"

for i in {0..64} ; do
    printf "\033[0;${i}m[0;%2d]\033[0m  \t" ${i}
    printf "\033[1;${i}m[1;%2d]\033[0m  \t" ${i}
    if [ $(( i % $BREAK2 )) -eq $(($BREAK2-1)) ] ; then
        printf "\n"
    fi
done
printf "\n"

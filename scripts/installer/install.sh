#!/usr/bin/env bash

SCRIPT_NAME=${BASH_SOURCE[0]}
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && cd ../  && pwd )"

# utility functions
#
function usage() {
    echo "$SCRIPT_NAME <application> [arguments...]"
}

# check arguments
#
if [ $# -eq 0 ]; then
    usage
    exit 1
else
    for arg in "$@"
    do
        if [ $arg = "-h" ] || [ $arg = "--help" ]; then
            usage
            exit 0
        fi
    done
fi

# find corresponded script and run
#
source $SCRIPT_DIR/util_funcs.sh
OS=$(get_platform)
APP=$1 ; shift
INSTALL_SCRIPT=$SCRIPT_DIR/installer/$OS/$APP

if [ -f "$INSTALL_SCRIPT" ]; then
    $INSTALL_SCRIPT $@
    exit $?
else
    echo "sorry, no proper script to install [$APP] on [$OS]"
    exit 1
fi


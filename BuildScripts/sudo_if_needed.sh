#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. $SCRIPT_DIR/term_styles.sh

if [ $# -ne 2 ]; then
    printf "${BRed} ERROR: missing command line parameters $# ${Color_Off}\n"
    printf " Usage: $0 <canary path> <command>\n"
    exit 1
fi

FILE_PATH=$1
COMMAND=$2
#printf "${Yellow}sudo_if_needed $COMMAND${Color_Off}\n"
if [ -e $FILE_PATH ]; then
    if [ -w $FILE_PATH ]; then
        eval $COMMAND 
        RESULT=$?
    else
        if ! sudo -n true 2>/dev/null; then 
            printf "${Blue}sudo may ask for credentials to access $FILE_PATH${Color_Off}\n"
        fi
        eval "sudo $COMMAND"
        RESULT=$?
    fi
fi
exit $RESULT
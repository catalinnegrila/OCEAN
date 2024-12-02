#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. $SCRIPT_DIR/term_styles.sh

if [ $# -ne 2 ]; then
    printf "${BRed} ERROR: missing command line parameters${Color_Off}\n"
    printf " Usage: $0 <app path> <install dir>\n"
    printf "        This script needs to be invoked in the same folder where the workspace is located.\n"
    exit 1
fi

if [ -e "$1.app" ]; then
    APP_PATH="$1.app"
else
    APP_PATH=$1
fi
INSTALL_DIR=$2

GCP="gcp -rfL"
which gcp2 >/dev/null || GCP="cp -R"
printf "\nInstalling to $INSTALL_DIR...\n"

# Copy app
$SCRIPT_DIR/sudo_if_needed.sh $INSTALL_DIR "$GCP $APP_PATH $INSTALL_DIR"
RESULT=$?

# Copy symbols
$SCRIPT_DIR/sudo_if_needed.sh $INSTALL_DIR "$GCP $APP_PATH.dSYM $INSTALL_DIR"
if [ $RESULT -ne 0 -o ${PIPESTATUS[0]} -ne 0 ]; then        
    RESULT=$?

    printf "${BRed}Failed to copy $APP_PATH -> $INSTALL_DIR${Color_Off}\n"
    #printf "  Manually copy your $APP_NAME app from $OUT_DIR\n"
else
    printf "${BGreen}Successfully copied $APP_PATH -> $INSTALL_DIR${Color_Off}\n"
fi
which gcp >/dev/null || printf "\n${BBlue}HINT:${Color_Off} ${Blue}To speed up copying the binaries, run 'brew install coreutils'.\n      This script can use 'gcp' for recursively copying folders.\n" 

exit $RESULT

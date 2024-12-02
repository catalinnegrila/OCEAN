#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. $SCRIPT_DIR/term_styles.sh

if [ $# -ne 3 ]; then
    printf "${BRed} ERROR: missing command line parameters${Color_Off}\n"
    printf " Usage: $0 <app name> <workspace dir> <install dir>\n"
    exit 1
fi

APP_NAME=$1
WORKSPACE_DIR=$2
INSTALL_DIR=$3

OUT_DIR="$WORKSPACE_DIR/bin"

# Clean up previous install
printf "Cleaning up previous installation in $INSTALL_DIR...\n"
FILE_PATH="$INSTALL_DIR/$APP_NAME"
if [ -e "$FILE_PATH.app" ]; then
    FILE_PATH="$FILE_PATH.app"
fi
$SCRIPT_DIR/sudo_if_needed.sh $FILE_PATH "rm -rf $FILE_PATH"

FILE_PATH="$FILE_PATH.dSYM"
$SCRIPT_DIR/sudo_if_needed.sh $FILE_PATH "rm -rf $FILE_PATH"

printf "\n"
"$SCRIPT_DIR/build_workspace.sh" $APP_NAME $WORKSPACE_DIR $OUT_DIR
RESULT=$?
if [ $RESULT -eq 0 ]; then
    "$SCRIPT_DIR/install_app.sh" "$OUT_DIR/$APP_NAME" $INSTALL_DIR
    RESULT=$?
fi
exit $RESULT

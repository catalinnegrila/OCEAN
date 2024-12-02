#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPT_DIR/term_styles.sh"

if [ $# -ne 3 ]; then
    printf "${BRed} ERROR: missing command line parameters${Color_Off}\n"
    printf " Usage: $0 <app name> <workspace dir> <build dir>\n"
    exit 1
fi

APP_NAME=$1
BASE_DIR=$2
WORKSPACE_PATH="$BASE_DIR/$APP_NAME.xcworkspace"
LOG_FILE="$BASE_DIR/xcodebuild.log" 
CONFIG="Release build CONFIGURATION_BUILD_DIR=$3"

printf "Building $APP_NAME...\n"
XCPRETTY="xcpretty"
which xcpretty >/dev/null || XCPRETTY="cat"
xcodebuild -workspace $WORKSPACE_PATH -scheme $APP_NAME -destination generic/platform=macOS -configuration $CONFIG | tee $LOG_FILE | eval $XCPRETTY
RESULT=$?

echo "Log saved in $LOG_FILE"
which xcpretty >/dev/null || printf "\n${BBlue}HINT:${Color_Off} ${Blue}Run 'gem install xcpretty' for clearer build output.${Color_Off}\n"
exit $RESULT

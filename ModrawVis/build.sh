#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BUILD_SCRIPTS="$(realpath $SCRIPT_DIR/../BuildScripts)"

# Update this to something sensible once off the ship
INSTALL_DIR="/Volumes/sci/shipside/SKQ202417S/Alex"

"$BUILD_SCRIPTS/build_and_install.sh" "ModrawVis" $SCRIPT_DIR $INSTALL_DIR

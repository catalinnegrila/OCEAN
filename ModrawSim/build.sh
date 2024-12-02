#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BUILD_SCRIPTS="$(realpath $SCRIPT_DIR/../BuildScripts)"

INSTALL_DIR="/usr/local/bin"

"$BUILD_SCRIPTS/build_and_install.sh" "ModrawSim" $SCRIPT_DIR $INSTALL_DIR

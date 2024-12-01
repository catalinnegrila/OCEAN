#!/bin/bash
TARGET_DIR="/Volumes/sci/shipside/SKQ202417S/Alex"
APP_NAME="FCTD EPSI Realtime Plot.app"
rm -rf "$TARGET_DIR/$APP_NAME"
rm -rf bin
xcodebuild archive
# brew install coreutils
gcp -rfL "bin/Release/$APP_NAME" $TARGET_DIR
gcp -rfL "bin/Release/$APP_NAME.dSYM" $TARGET_DIR  
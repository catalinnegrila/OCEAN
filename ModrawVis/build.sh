#!/bin/bash
TARGET_DIR="/Volumes/sci/shipside/SKQ202417S/Alex"
APP_NAME="ModrawVis"
ARCHIVE_NAME="Latest"
rm -rf $TARGET_DIR/$APP_NAME.*
rm -rf $ARCHIVE_NAME.*

xcodebuild archive -workspace $APP_NAME.xcworkspace -scheme $APP_NAME -configuration Release -archivePath $ARCHIVE_NAME

# brew install coreutils
gcp -rfL "$ARCHIVE_NAME.xcarchive/Products/Applications/$APP_NAME.app" $TARGET_DIR
gcp -rfL "$ARCHIVE_NAME.xcarchive/dSYMs/$APP_NAME.app.dSYM" $TARGET_DIR  
#!/bin/bash
APP_NAME="ModrawSim"
ARCHIVE_NAME="Latest"
INSTALL_LOCATION="/usr/local/bin"

rm -rf $ARCHIVE_NAME.*
xcodebuild archive -workspace $APP_NAME.xcworkspace -scheme $APP_NAME -configuration Release -archivePath $ARCHIVE_NAME
echo sudo may prompt for credentials to install $APP_NAME to $INSTALL_LOCATION
sudo cp $ARCHIVE_NAME.xcarchive/Products/$INSTALL_LOCATION/$APP_NAME $INSTALL_LOCATION

#!/bin/bash
TARGET_DIR="/Volumes/sci/shipside/SKQ202417S/Alex"
rm -rf $TARGET_DIR/epsiPlot_realtime.app
rm -rf bin
xcodebuild archive
# brew install coreutils
gcp -rfLv bin/Release/epsiPlot_realtime.app $TARGET_DIR  
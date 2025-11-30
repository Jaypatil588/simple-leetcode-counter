#!/bin/bash

# Script to run LeetcodeCounter app without Xcode
# This script finds and launches the built app

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_PATH="$SCRIPT_DIR/build/Build/Products/Release/LeetcodeCounter.app"

# Check if Release build exists, fallback to Debug
if [ ! -d "$APP_PATH" ]; then
    APP_PATH="$SCRIPT_DIR/build/Build/Products/Debug/LeetcodeCounter.app"
fi

# If still not found, try to find it in DerivedData
if [ ! -d "$APP_PATH" ]; then
    echo "App not found. Building the app..."
    cd "$SCRIPT_DIR"
    xcodebuild -project LeetcodeCounter.xcodeproj \
               -scheme LeetcodeCounter \
               -configuration Release \
               -derivedDataPath ./build \
               clean build > /dev/null 2>&1
    
    APP_PATH="$SCRIPT_DIR/build/Build/Products/Release/LeetcodeCounter.app"
fi

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Could not find or build LeetcodeCounter.app"
    echo "Please build the app in Xcode first (Product > Build)"
    exit 1
fi

# Kill any existing instances
killall LeetcodeCounter 2>/dev/null

# Run the app
echo "🚀 Launching LeetcodeCounter..."
open "$APP_PATH"

echo "✅ App launched! You can close this terminal window."
echo "📍 App location: $APP_PATH"

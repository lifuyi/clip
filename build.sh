#!/bin/bash

# Clipy Advanced Clipboard Manager Build Script

echo "Building Clipy - Advanced Clipboard Manager..."

# Build the project using Swift Package Manager
echo "Building with Swift Package Manager..."
swift build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # Create app bundle structure
    echo "Creating app bundle..."
    mkdir -p Clipy.app/Contents/MacOS
    mkdir -p Clipy.app/Contents/Resources
    
    # Copy the executable
    cp ./.build/arm64-apple-macosx/debug/Clipy Clipy.app/Contents/MacOS/Clipy
    
    # Copy Info.plist if it doesn't exist
    if [ ! -f "Clipy.app/Contents/Info.plist" ]; then
        cp Info.plist Clipy.app/Contents/Info.plist
    fi
    
    echo "App bundle created at Clipy.app"
    echo ""
    echo "Features implemented:"
    echo "✓ Advanced clipboard monitoring with multiple data types"
    echo "✓ Persistent clipboard history with file storage"
    echo "✓ Snippet management system with folders"
    echo "✓ Menu management with dynamic updates"
    echo "✓ Preferences window with customizable settings"
    echo "✓ Sound effects and visual feedback"
    echo "✓ Color code detection and preview"
    echo "✓ Image thumbnail support"
    echo "✓ Numeric keyboard shortcuts"
    echo "✓ Login items integration"
    echo ""
    echo "To run the application:"
    echo "  ./Clipy.app/Contents/MacOS/Clipy"
    echo "or"
    echo "  open Clipy.app"
    echo ""
    echo "The application will appear in your macOS menu bar as 📋"
else
    echo "Build failed!"
    exit 1
fi

if [ "$1" = "run" ]; then
    echo "Starting Clipy..."
    open Clipy.app
fi
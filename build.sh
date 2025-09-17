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
    
    # Copy entitlements file if it exists
    if [ -f "Clipy.entitlements" ]; then
        cp Clipy.entitlements Clipy.app/Contents/
        echo "Entitlements file copied to app bundle"
        
        # Try to sign the app with entitlements (if codesign is available)
        if command -v codesign >/dev/null 2>&1; then
            echo "Attempting to sign app with entitlements..."
            codesign --force --sign - --entitlements Clipy.entitlements Clipy.app 2>/dev/null || {
                echo "Note: Code signing failed (this is normal for debug builds)"
            }
        fi
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
    echo "✓ Enhanced paste functionality with multiple fallback methods"
    echo ""
    echo "IMPORTANT: Launch Method for Best Paste Functionality"
    echo "==========================================================="
    echo ""
    echo "For FULL paste functionality (recommended):"
    echo "  ./Clipy.app/Contents/MacOS/Clipy"
    echo ""
    echo "Alternative method (paste limitations):"
    echo "  open Clipy.app"
    echo "  → When using 'open', automatic paste may not work due to macOS security"
    echo "  → Content will still be copied to clipboard for manual paste (⌘+V)"
    echo ""
    echo "The application will appear in your macOS menu bar as 📋"
    echo ""
    echo "PASTE FUNCTIONALITY REQUIREMENTS:"
    echo "- Accessibility permissions (System Preferences > Security & Privacy > Privacy > Accessibility)"
    echo "- AppleScript permissions (will be prompted automatically)"
    echo "- For best results: run directly from terminal, not via 'open' command"
    echo ""
    echo "If paste doesn't work automatically, the app will:"
    echo "1. Copy content to clipboard"
    echo "2. Show notification to press ⌘+V manually"
    echo "3. Provide guidance on fixing permissions"
else
    echo "Build failed!"
    exit 1
fi

if [ "$1" = "run" ]; then
    echo "Starting Clipy..."
    ./Clipy.app/Contents/MacOS/Clipy
fi
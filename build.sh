#!/bin/bash

# MyClipyMenuBar Build Script

echo "Building MyClipyMenuBar..."

# Build the project using Swift Package Manager
echo "Building with Swift Package Manager..."
swift build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # Create app bundle structure
    echo "Creating app bundle..."
    mkdir -p MyClipy.app/Contents/MacOS
    
    # Copy the executable
    cp .build/debug/MyClipyMenuBar MyClipy.app/Contents/MacOS/MyClipy
    
    # Copy Info.plist if it doesn't exist
    if [ ! -f "MyClipy.app/Contents/Info.plist" ]; then
        cp Info.plist MyClipy.app/Contents/Info.plist
    fi
    
    echo "App bundle created at MyClipy.app"
    echo ""
    echo "To run the application:"
    echo "  ./MyClipy.app/Contents/MacOS/MyClipy"
    echo "or"
    echo "  open MyClipy.app"
    echo ""
    echo "The application will appear in your macOS menu bar as a clipboard icon."
else
    echo "Build failed!"
    exit 1
fi
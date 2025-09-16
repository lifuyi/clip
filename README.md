# MyClipyMenuBar

A simple clipboard manager for macOS with a menu bar interface that can be built without Xcode.

## Overview

MyClipyMenuBar is a lightweight clipboard manager that runs in the macOS menu bar. It monitors your clipboard and keeps a history of copied items that you can access with a simple click.

## Features

- Menu bar integration with clipboard icon
- Automatic clipboard monitoring
- History of copied items (up to 20 items)
- Quick access to clipboard history
- Clean and simple interface
- No Xcode required for building

## Requirements

- macOS 10.15 or later
- Swift 5.3 or later (command line tools)

## Building the Project

This project uses Swift Package Manager for building:

1. Navigate to the project directory
2. Build the project:
   ```
   swift build
   ```

3. Create app bundle:
   ```
   mkdir -p MyClipy.app/Contents/MacOS
   cp .build/debug/MyClipyMenuBar MyClipy.app/Contents/MacOS/MyClipy
   cp Info.plist MyClipy.app/Contents/
   ```

## Running the Application

To run the application directly:
```
.build/debug/MyClipyMenuBar
```

To run the app bundle:
```
open MyClipy.app
```

The application will:
1. Appear as a clipboard icon in your macOS menu bar
2. Automatically monitor your clipboard for changes
3. Keep a history of up to 20 clipboard items
4. Allow you to access and copy previous clipboard items

## Usage

1. Run the application
2. Look for the clipboard icon (📋) in your macOS menu bar
3. Copy text in any application (the copied text will be added to history)
4. Click the clipboard icon to open the menu
5. Select any item from the history to copy it back to the clipboard
6. Use "Clear History" to remove all items
7. Use "Quit" to exit the application

## How It Works

- The application uses `NSStatusBar` to create a menu bar item
- A timer checks `NSPasteboard.general.changeCount` every 0.5 seconds
- When a change is detected, it reads the clipboard content
- Items are stored in memory with deduplication
- The menu is updated automatically when new items are added

## Limitations

- Only monitors plain text clipboard content
- No persistent storage (history is lost when the app quits)
- No snippet management
- No preferences configuration

## License

This project is licensed under the MIT License.
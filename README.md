# Clipy - Advanced Clipboard Manager

A comprehensive clipboard manager for macOS that extends your clipboard functionality with advanced features, persistent history, and snippet management.

## Overview

Clipy is a feature-rich clipboard manager that runs in the macOS menu bar. Based on the popular Clipy application architecture, it provides advanced clipboard monitoring, persistent storage, snippet management, and extensive customization options.

## Features

### Core Clipboard Management
- **Real-time Monitoring**: Monitor clipboard changes across all data types (text, images, RTF, PDF, files)
- **Persistent History**: Store clipboard history with automatic persistence to disk
- **Smart Deduplication**: Automatically remove duplicate entries
- **Multiple Data Types**: Support for text, images, RTF documents, PDF files, and file URLs
- **Memory Management**: Configurable history size limits with automatic cleanup

### Advanced Menu System
- **Dynamic Menus**: Automatically updating menu system with live clipboard data
- **Numeric Shortcuts**: Keyboard shortcuts (0-9) for quick access to recent items
- **Inline Display**: Configurable number of items shown directly in menu
- **Submenu Organization**: Organize large histories in nested menus
- **Visual Previews**: Thumbnail previews for images and color codes

### Snippet Management
- **Organized Snippets**: Create and organize text snippets in folders
- **Snippet Editor**: Full-featured editor for managing snippets
- **Quick Access**: Fast insertion of frequently used text
- **Folder Organization**: Hierarchical organization with drag-and-drop support

### Smart Features
- **Color Detection**: Automatic detection and preview of hex color codes
- **Image Thumbnails**: Generate and display thumbnails for images
- **App Exclusion**: Exclude specific applications from clipboard monitoring
- **Sound Feedback**: Customizable sound effects for clipboard operations

### Preferences & Customization
- **Comprehensive Settings**: Detailed preferences window with multiple panels
- **Visual Customization**: Configure menu icons, image display, and color previews
- **Timing Controls**: Adjustable monitoring intervals
- **Login Items**: Optional launch at login functionality

## Requirements

- macOS 10.12 or later
- Swift 5.3 or later (command line tools)

## Building the Project

Use the provided build script for easy building:

```bash
chmod +x build.sh
./build.sh
```

To build and run immediately:
```bash
./build.sh run
```

Or manually with Swift Package Manager:
```bash
swift build
```

## Running the Application

After building, run the application:
```bash
open Clipy.app
```

Or directly (recommended for best paste functionality):
```bash
./Clipy.app/Contents/MacOS/Clipy
```

### Paste Functionality Notes

For full paste functionality, Clipy requires accessibility permissions. Due to macOS security restrictions, the paste feature works more reliably when running the application directly from the command line rather than using the `open` command.

If paste functionality doesn't work:
1. Grant accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility
2. Consider running Clipy directly from Terminal for best compatibility
3. Refer to the `paste_troubleshooting_guide.md` for detailed troubleshooting steps

For comprehensive troubleshooting of paste issues, please see the `paste_troubleshooting_guide.md` file.

## Usage

### Basic Operation
1. Copy any content (text, images, files) to your clipboard
2. Click the 📋 icon in your menu bar to access your clipboard history
3. Select any item to paste it back to your clipboard
4. Use numeric keys (0-9) for quick access to recent items

### Managing Snippets
1. Click "Edit Snippets..." from the menu
2. Create folders to organize your snippets
3. Add frequently used text snippets
4. Access snippets from the "Snippets" submenu

### Customizing Settings
1. Click "Preferences..." from the menu
2. Configure history size, sound effects, visual options
3. Set up app exclusions and monitoring intervals
4. Enable/disable login at startup

## Architecture

The application follows modern Swift development patterns:

- **Constants.swift**: Application-wide configuration and constants
- **Models.swift**: Data models for clips, snippets, folders, and app info
- **Services.swift**: Core business logic services (ClipService, MenuManager, SnippetService, PasteService)
- **Extensions.swift**: Useful extensions for system types and utilities
- **PreferencesWindow.swift**: UI controllers for preferences and snippet editor
- **main.swift**: Application delegate and main menu management

## Data Storage

- Clipboard data stored in `~/Library/Application Support/Clipy/`
- Thumbnails and metadata cached for performance
- Preferences managed through UserDefaults
- Automatic cleanup of old data files
- Thread-safe file operations with proper locking

## Technical Features

### Service Architecture
- **ClipService**: Handles clipboard monitoring and data management
- **MenuManager**: Manages dynamic menu creation and updates
- **SnippetService**: Handles snippet and folder management
- **PasteService**: Manages paste operations and event simulation

### Advanced Capabilities
- **Multi-format Support**: Text, RTF, images, PDFs, file URLs
- **Smart Paste**: Automatic paste simulation with proper event handling
- **Memory Optimization**: Efficient storage and retrieval of clipboard data
- **Error Handling**: Robust error handling and recovery mechanisms

## Implemented Features from Clipy Specification

✅ **Core Features**
- Comprehensive clipboard monitoring
- Persistent data storage
- Advanced menu management
- Snippet system with folders
- Preferences system

✅ **Advanced Features**
- Color code detection and preview
- Image thumbnail generation
- Numeric keyboard shortcuts
- Sound effects and feedback
- App exclusion system
- Login items integration

✅ **Architecture Patterns**
- MVVM architecture
- Service-oriented design
- Protocol-oriented programming
- Reactive-style updates
- Thread-safe operations

## License

This project is licensed under the MIT License.
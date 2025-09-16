# IFLOW.md - Clipy Advanced Clipboard Manager

## Project Overview

Clipy is an advanced clipboard manager for macOS that extends clipboard functionality with persistent history, snippet management, and real-time monitoring. The application runs in the macOS menu bar and provides features like smart deduplication, multiple data type support (text, images, RTF, PDF, files), and customizable preferences.

## Building and Running

### Prerequisites
- macOS 10.12 or later
- Swift 5.3 or later (command line tools)

### Building the Project

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

### Running the Application

After building, run the application:
```bash
open Clipy.app
```

Or directly:
```bash
./Clipy.app/Contents/MacOS/Clipy
```

## Architecture

The application follows modern Swift development patterns with a service-oriented architecture:

- **Constants.swift**: Application-wide configuration and constants
- **Models.swift**: Data models for clips, snippets, folders, and app info
- **Services.swift**: Core business logic services (ClipService, MenuManager, SnippetService, PasteService)
- **Extensions.swift**: Useful extensions for system types and utilities
- **PreferencesWindow.swift**: UI controllers for preferences and snippet editor
- **main.swift**: Application delegate and main menu management

## Key Features

### Core Clipboard Management
- Real-time monitoring of clipboard changes across all data types
- Persistent history storage with automatic disk persistence
- Smart deduplication to remove duplicate entries
- Support for text, images, RTF documents, PDF files, and file URLs
- Configurable history size limits with automatic cleanup

### Advanced Menu System
- Dynamic menus with live clipboard data updates
- Numeric shortcuts (0-9) for quick access to recent items
- Configurable number of items shown directly in menu
- Submenu organization for large histories
- Visual previews including thumbnail images and color codes

### Snippet Management
- Create and organize text snippets in folders
- Snippet editor for managing snippets
- Quick insertion of frequently used text
- Hierarchical organization with drag-and-drop support

### Smart Features
- Automatic detection and preview of hex color codes
- Image thumbnail generation and display
- App exclusion to prevent monitoring in specific applications
- Customizable sound effects for clipboard operations

### Preferences & Customization
- Comprehensive settings window with multiple panels
- Visual customization options for menu icons, images, and color previews
- Adjustable monitoring intervals
- Optional launch at login functionality

## Data Storage

- Clipboard data stored in `~/Library/Application Support/Clipy/`
- Thumbnails and metadata cached for performance
- Preferences managed through UserDefaults
- Automatic cleanup of old data files
- Thread-safe file operations with proper locking

## Development Conventions

- Swift-based macOS application using AppKit
- Service-oriented architecture with clear separation of concerns
- Reactive-style updates using NotificationCenter
- Protocol-oriented programming patterns
- Thread-safe operations for data handling
- MVVM architecture for UI components
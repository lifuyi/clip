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

For FULL paste functionality (recommended):
```bash
./Clipy.app/Contents/MacOS/Clipy
```

Alternative method (paste limitations):
```bash
open Clipy.app
```
→ When using 'open', automatic paste may not work due to macOS security
→ Content will still be copied to clipboard for manual paste (⌘+V)

### Paste Functionality Notes

For full paste functionality, Clipy requires accessibility permissions. Due to macOS security restrictions, the paste feature works more reliably when running the application directly from the command line rather than using the `open` command.

If paste functionality doesn't work:
1. Grant accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility
2. Consider running Clipy directly from Terminal for best compatibility

The application will appear in your macOS menu bar as 📋

PASTE FUNCTIONALITY REQUIREMENTS:
- Accessibility permissions (System Preferences > Security & Privacy > Privacy > Accessibility)
- AppleScript permissions (will be prompted automatically)
- For best results: run directly from terminal, not via 'open' command

If paste doesn't work automatically, the app will:
1. Copy content to clipboard
2. Show notification to press ⌘+V manually
3. Provide guidance on fixing permissions

## Architecture

The application follows modern Swift development patterns with a service-oriented architecture:

- **Constants.swift**: Application-wide configuration and constants
- **Models.swift**: Data models for clips, snippets, folders, and app info
- **Services.swift**: Core business logic services (ClipService, MenuManager, SnippetService, PasteService)
- **Extensions.swift**: Useful extensions for system types and utilities
- **PreferencesWindow.swift**: UI controllers for preferences and snippet editor
- **UIConstants.swift**: UI styling constants and extensions
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

### Enhanced Paste Functionality
- Multiple paste methods with fallback mechanisms
- AppleScript integration for primary paste method
- CGEvent simulation with multiple approaches
- Comprehensive permission checking and user guidance
- Graceful degradation to clipboard-only operation

### Preferences & Customization
- Comprehensive settings window with multiple panels
- Visual customization options for menu icons, images, and color previews
- Adjustable monitoring intervals
- Optional launch at login functionality
- Configurable number of recent items to show in main menu
- Multiple sound effect options with preview functionality

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

## Implementation Details

### Enhanced Paste Service
The PasteService implements multiple methods for pasting content:
1. **AppleScript Method**: Primary method when accessibility permissions are granted
2. **HID Event Tap**: Direct keyboard event simulation
3. **CGEvent Combined Session**: Alternative event posting methods
4. **Alternative Timing Approaches**: Different delay strategies for better compatibility
5. **Aggressive Paste**: Multiple simultaneous approaches as last resort
6. **Manual Paste Fallback**: Shows notification when automatic paste fails

### Permission Handling
Clipy now includes comprehensive permission checking:
- Accessibility permissions verification
- AppleScript permissions testing
- User-friendly alerts with guidance
- Direct links to system preferences
- Launch method detection (open command vs direct execution)

### UI Improvements
- Modern styled preferences window with scroll view
- Enhanced snippet editor with continuous input functionality
- Improved styling with UIConstants
- Better error handling and user feedback

### Code Structure
- Clear separation of concerns with dedicated service classes
- Extensive use of extensions for code organization
- Comprehensive error handling throughout
- Thread-safe operations for data handling
- Modern Swift syntax and patterns
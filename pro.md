# Clipy - Comprehensive Function Summary

## Overview
This document provides a comprehensive summary of all functions, methods, and classes in the Clipy macOS clipboard extension application. The codebase is written in Swift and follows a service-oriented architecture pattern with custom data persistence.

---

## Core Application Structure

### main.swift
**Main application delegate handling lifecycle and menu actions**

#### Classes
- `AppDelegate: NSObject, NSApplicationDelegate`

#### Key Functions
- `applicationDidFinishLaunching(_:)` - App launch setup with permission checking
- `applicationWillFinishLaunching(_:)` - Pre-launch setup
- `setupMenuBar()` - Initialize menu bar interface
- `setupServices()` - Initialize core services
- `setupObservers()` - Setup notification observers
- `updateMainMenu()` - Update main menu with current data
- `selectClipMenuItem(_:)` - Handle clip selection from menu
- `selectSnippetMenuItem(_:)` - Handle snippet selection from menu
- `clearAllHistory()` - Clear clipboard history with confirmation
- `showPreferencesWindow()` - Display preferences window
- `showSnippetEditorWindow()` - Display snippet editor
- `showAbout()` - Show application about panel
- `terminate()` - Terminate application
- `popUpMainMenu()` - Show main menu via hotkey
- `popUpHistoryMenu()` - Show history menu via hotkey
- `popUpSnippetMenu()` - Show snippet menu via hotkey
- `validateMenuItem(_:)` - Validate menu items
- `checkAccessibilityPermissions()` - Check and request accessibility permissions
- `testAppleScriptPermissions()` - Test AppleScript permissions

---

## Constants and Configuration

### Constants.swift
**Application-wide constants and configuration values**

#### Structures
- `Constants` - Main constants container
  - `Application` - App name and identifiers
  - `Menu` - Menu configuration values
  - `UserDefaults` - UserDefaults keys
  - `Notification` - Notification names
  - `SoundEffect` - Sound effect identifiers

#### Enums
- `CPYSoundEffectType` - Available sound effect types with system IDs

---

## Extensions

### Extensions.swift
**Utility extensions for system types**

#### Extension Methods
- `Array.removeObject(_:)` - Remove single object from array
- `Array.removeObjects(_:)` - Remove multiple objects from array
- `Collection.subscript(safe:)` - Safe index access
- `Bundle.appVersion` - Get app version from info dictionary
- `NSCoding.archive()` - Archive NSCoding object
- `Array.archive()` - Archive array of NSCoding objects
- `NSImage.create(with:size:)` - Create image from color
- `NSImage.resizeImage(_:_:)` - Resize image maintaining aspect ratio
- `NSMenuItem.init(title:action:)` - Create menu item with title and action
- `UserDefaults.setArchiveData(_:forKey:)` - Store archived object
- `UserDefaults.archiveDataForKey(_:key:)` - Retrieve archived object
- `String.subscript(range:)` - Safe substring access
- `NSLock.init(name:)` - Initialize lock with name

---

## Models

### Models.swift
**Data models for clipboard items, snippets, and folders**

#### Classes
- `CPYAppInfo: NSObject, NSCoding` - Application information model
- `CPYClipData: NSObject, NSCoding, NSSecureCoding` - Clipboard data container
- `CPYClip: NSObject` - Clipboard item model
- `CPYSnippet: NSObject` - Text snippet model
- `CPYFolder: NSObject` - Snippet folder model
- `CPYUtilities` - Application utilities

#### Key Properties (CPYClipData)
- `types`, `fileNames`, `URLs`, `stringValue`, `RTFData`, `PDF`, `image`
- `hash: Int` - Computed hash value
- `primaryType`, `isOnlyStringType`, `thumbnailImage`, `colorCodeImage`

#### Key Functions (CPYClipData)
- `init(pasteboard:types:)` - Initialize from pasteboard
- `init(image:)` - Initialize with image
- `init(coder:)` - NSCoding decoder
- `encode(with:)` - NSCoding encoder

#### Static Properties (CPYClipData)
- `availableTypes`, `availableTypesString`, `availableTypesDictionary`

#### Key Properties (CPYClip)
- `identifier`, `dataPath`, `title`, `dataHash`, `primaryType`, `updateTime`, `thumbnailPath`, `isColorCode`

#### Key Properties (CPYSnippet)
- `identifier`, `title`, `content`, `enable`, `index`

#### Key Properties (CPYFolder)
- `identifier`, `title`, `enable`, `index`, `snippets`

#### Key Functions (CPYUtilities)
- `applicationSupportFolder()` - Get app support directory
- `registerUserDefaultKeys()` - Register default UserDefaults values

---

## Services

### Services.swift
**Core business logic services**

#### Classes
- `ClipService: NSObject` - Clipboard monitoring and management
- `MenuManager: NSObject` - Menu creation and management
- `SnippetService: NSObject` - Snippet and folder management
- `PasteService: NSObject` - Paste operation management

#### Key Functions (ClipService)
- `startMonitoring()` - Begin clipboard monitoring
- `stopMonitoring()` - Stop clipboard monitoring
- `getAllClips()` - Get all clipboard items
- `clearAll()` - Clear all clipboard history
- `delete(clip:)` - Delete specific clip
- `playSoundEffect()` - Play sound effect when adding clip

#### Key Functions (MenuManager)
- `createHistoryMenu()` - Create history submenu
- `createSnippetMenu()` - Create snippet submenu
- `clipDataUpdated()` - Handle clip data updates

#### Key Functions (SnippetService)
- `getAllSnippets()` - Get all snippets
- `getAllFolders()` - Get all folders
- `createFolder(title:)` - Create new folder
- `deleteFolder(_:)` - Delete folder
- `createSnippet(in:title:content:)` - Create new snippet
- `deleteSnippet(_:from:)` - Delete snippet

#### Key Functions (PasteService)
- `paste(clip:)` - Paste clip content
- `paste(snippet:)` - Paste snippet content
- `performPasteToFocusedApp()` - Perform paste to focused application
- `performPasteWithAppleScript()` - Paste using AppleScript
- `simulatePasteWithHIDEventTap()` - Paste using HID event tap
- `simulatePasteWithCGEventCombined()` - Paste using combined CGEvent
- `simulatePasteWithAlternativeTiming()` - Paste with alternative timing
- `performAggressivePaste()` - Aggressive paste as last resort
- `showManualPasteNotification()` - Show manual paste notification

---

## Preferences

### PreferencesWindow.swift
**Preferences and snippet editor windows**

#### Classes
- `PreferencesWindowController: NSWindowController` - Main preferences window controller
- `SnippetEditorWindowController: NSWindowController` - Snippet editor window controller

#### Key Functions (PreferencesWindowController)
- `setupUI()` - Setup preferences UI
- `loadPreferences()` - Load preferences from UserDefaults
- `maxHistorySizeChanged(_:)` - Handle max history size change
- `maxMenuItemTitleLengthChanged(_:)` - Handle menu title length change
- `showImageToggled(_:)` - Handle show image toggle
- `colorPreviewToggled(_:)` - Handle color preview toggle
- `numericKeysToggled(_:)` - Handle numeric keys toggle
- `soundEffectToggled(_:)` - Handle sound effect toggle
- `soundEffectTypeChanged(_:)` - Handle sound effect type change
- `timeIntervalChanged(_:)` - Handle time interval change
- `launchAtLoginToggled(_:)` - Handle launch at login toggle
- `resetToDefaults(_:)` - Reset preferences to defaults

#### Key Functions (SnippetEditorWindowController)
- `setupUI()` - Setup snippet editor UI
- `addSnippet()` - Add new snippet
- `removeSnippet()` - Remove selected snippet(s)
- `saveSnippet()` - Save current snippet
- `updateSnippetList()` - Update snippet list display
- `clearEditor()` - Clear editor fields
- `updateEditor(with:)` - Update editor with snippet data

---

## UI Constants and Styling

### UIConstants.swift
**UI constants and styling extensions**

#### Structures
- `UIConstants.Colors` - Color scheme
- `UIConstants.Typography` - Font definitions
- `UIConstants.Spacing` - Spacing values
- `UIConstants.Sizing` - Sizing values
- `UIConstants.CornerRadius` - Corner radius values

#### Extension Methods
- `NSView.setCornerRadius(_:)` - Set corner radius
- `NSView.setBackgroundColor(_:)` - Set background color
- `NSButton.styleAsPrimaryButton()` - Style as primary button
- `NSButton.styleAsSecondaryButton()` - Style as secondary button
- `NSButton.styleAsDestructiveButton()` - Style as destructive button
- `NSTextField.styleAsTitleLabel()` - Style as title label
- `NSTextField.styleAsSectionHeader()` - Style as section header
- `NSTextField.styleAsBodyLabel()` - Style as body label
- `NSTextField.styleAsCaptionLabel()` - Style as caption label
- `NSTextField.styleAsTextField()` - Style as text field

---

## Architecture Summary

### Key Patterns Used
1. **Service-Oriented Architecture** - Clear separation of concerns with dedicated service classes
2. **Notification Pattern** - NotificationCenter for communication between components
3. **Protocol-Oriented Design** - Extensive use of protocols and extensions
4. **Custom Data Persistence** - File-based storage with NSKeyedArchiving
5. **Command Pattern** - Menu actions and hotkey handling

### Core Components
1. **Clipboard Monitoring** - Real-time pasteboard observation
2. **Data Persistence** - File-based storage with custom serialization
3. **Menu Management** - Dynamic menu creation and updates
4. **Snippet Management** - Text snippet organization and editing
5. **Preference System** - Multi-panel preferences with data binding
6. **Enhanced Paste Functionality** - Multiple paste methods with fallback mechanisms

### Service Layer
- **ClipService** - Clipboard data management
- **MenuManager** - Menu creation and display
- **SnippetService** - Snippet and folder management
- **PasteService** - Paste operation handling with multiple fallback methods

This comprehensive function summary covers all major components, classes, and methods in the Clipy application codebase, providing a complete overview of the application's functionality and architecture.
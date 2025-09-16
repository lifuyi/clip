# Clipy - Comprehensive Function Summary

## Overview
This document provides a comprehensive summary of all functions, methods, and classes in the Clipy macOS clipboard extension application. The codebase is written in Swift and follows the MVVM architecture pattern with Realm database integration.

---

## Core Application Structure

### AppDelegate.swift
**Main application delegate handling lifecycle and menu actions**

#### Classes
- `AppDelegate: NSObject, NSMenuItemValidation`

#### Key Functions
- `awakeFromNib()` - Initialize Realm migration
- `validateMenuItem(_:) -> Bool` - Validate menu items (clear history)
- `storeTypesDictinary() -> [String: NSNumber]` - Create default store types
- `showPreferenceWindow()` - Display preferences window
- `showSnippetEditorWindow()` - Display snippet editor
- `terminate()` - Terminate application
- `clearAllHistory()` - Clear clipboard history with confirmation
- `selectClipMenuItem(_:)` - Handle clip selection from menu
- `selectSnippetMenuItem(_:)` - Handle snippet selection from menu
- `terminateApplication()` - Application termination
- `promptToAddLoginItems()` - Prompt user for login item setup
- `toggleAddingToLoginItems(_:)` - Add/remove from login items
- `reflectLoginItemState()` - Update login item state
- `applicationDidFinishLaunching(_:)` - App launch setup
- `applicationWillFinishLaunching(_:)` - Pre-launch setup
- `bind()` - Bind reactive observers

---

## Constants and Configuration

### Constants.swift
**Application-wide constants and configuration values**

#### Structures
- `Constants` - Main constants container
  - `Application` - App name and URLs
  - `Menu` - Menu identifiers
  - `Common` - Common string constants
  - `UserDefaults` - UserDefaults keys
  - `Beta` - Beta feature keys
  - `Update` - Update configuration
  - `Notification` - Notification names
  - `Xml` - XML element names
  - `HotKey` - Hotkey identifiers

---

## Environment and Dependency Injection

### Environment.swift
**Dependency injection container**

#### Structures
- `Environment` - Service container
  - `init()` - Initialize with default services

### AppEnvironment.swift
**Environment stack management**

#### Structures
- `AppEnvironment` - Environment stack manager

#### Key Functions
- `push(environment:)` - Push environment to stack
- `popLast() -> Environment?` - Pop last environment
- `replaceCurrent(environment:)` - Replace current environment
- `fromStorage() -> Environment` - Load from UserDefaults

---

## Enums

### MenuType.swift
**Menu type enumeration**

#### Enums
- `MenuType: String` - Menu types (main, history, snippet)

#### Key Properties
- `userDefaultsKey: String` - UserDefaults key for hotkey
- `hotKeySelector: Selector` - Selector for hotkey action

---

## Extensions

### Array+Remove.swift
**Array extension for object removal**

#### Extension Methods
- `removeObject<T: Equatable>(_:)` - Remove single object
- `removeObjects<T: Equatable>(_:)` - Remove multiple objects

### Collection+Safe.swift
**Safe collection access**

#### Extension Methods
- `subscript(safe:) -> Element?` - Safe index access

### NSBundle+Version.swift
**Bundle version utilities**

#### Extension Properties
- `appVersion: String?` - App version from info dictionary

### NSCoding+Archive.swift
**NSCoding archiving utilities**

#### Extension Methods
- `archive() -> Data` - Archive NSCoding object
- `archive() -> Data` - Archive NSCoding array

### NSImage+NSColor.swift
**Image creation from colors**

#### Extension Methods
- `create(with:size:) -> NSImage` - Create image from color

### NSImage+Resize.swift
**Image resizing utilities**

#### Extension Methods
- `resizeImage(_:_:) -> NSImage?` - Resize image maintaining aspect ratio

### NSLock+Clipy.swift
**Lock naming convenience**

#### Extension Methods
- `init(name:)` - Initialize lock with name

### NSMenuItem+Initialize.swift
**Menu item creation convenience**

#### Extension Methods
- `init(title:action:)` - Create menu item with title and action

### NSPasteboard+Deprecated.swift
**Deprecated pasteboard type compatibility**

#### Extension Properties
- `deprecatedString`, `deprecatedRTF`, etc. - Legacy pasteboard types

### NSUserDefaults+ArchiveData.swift
**UserDefaults archiving utilities**

#### Extension Methods
- `setArchiveData<T: NSCoding>(_:forKey:)` - Store archived object
- `archiveDataForKey<T: NSCoding>(_:key:) -> T?` - Retrieve archived object

### Realm+Migration.swift
**Realm database migration**

#### Extension Methods
- `migration()` - Perform database schema migration

### Realm+NoCatch.swift
**Realm transaction utilities**

#### Extension Methods
- `transaction(_:)` - Execute transaction without catching errors

### String+Substring.swift
**String subscript utilities**

#### Extension Methods
- `subscript(range:) -> String` - Safe substring access

---

## Models

### CPYAppInfo.swift
**Application information model**

#### Classes
- `CPYAppInfo: NSObject, NSCoding`

#### Key Functions
- `init?(info:)` - Initialize from app info dictionary
- `init?(coder:)` - NSCoding decoder
- `encode(with:)` - NSCoding encoder
- `isEqual(_:) -> Bool` - Equality comparison

### CPYClip.swift
**Clipboard item model**

#### Classes
- `CPYClip: Object` (Realm)

#### Key Properties
- `dataPath`, `title`, `dataHash`, `primaryType`, `updateTime`, `thumbnailPath`, `isColorCode`

#### Key Functions
- `primaryKey() -> String?` - Realm primary key

### CPYClipData.swift
**Clipboard data container**

#### Classes
- `CPYClipData: NSObject`

#### Key Properties
- `types`, `fileNames`, `URLs`, `stringValue`, `RTFData`, `PDF`, `image`
- `hash: Int` - Computed hash value
- `primaryType`, `isOnlyStringType`, `thumbnailImage`, `colorCodeImage`

#### Key Functions
- `init(pasteboard:types:)` - Initialize from pasteboard
- `init(image:)` - Initialize with image
- `encodeWithCoder(_:)` - NSCoding encoder
- `init(coder:)` - NSCoding decoder

#### Static Properties
- `availableTypes`, `availableTypesString`, `availableTypesDictinary`

### CPYDraggedData.swift
**Drag and drop data model**

#### Classes
- `CPYDraggedData: NSObject, NSCoding`

#### Enums
- `DragType: Int` - folder, snippet

#### Key Functions
- `init(type:folderIdentifier:snippetIdentifier:index:)` - Initialize drag data
- `init?(coder:)` - NSCoding decoder
- `encode(with:)` - NSCoding encoder

### CPYFolder.swift
**Snippet folder model**

#### Classes
- `CPYFolder: Object` (Realm)

#### Key Properties
- `index`, `enable`, `title`, `identifier`, `snippets`

#### Key Functions
- `primaryKey() -> String?` - Realm primary key
- `deepCopy() -> CPYFolder` - Create deep copy
- `createSnippet() -> CPYSnippet` - Create new snippet
- `mergeSnippet(_:)` - Add snippet to folder
- `insertSnippet(_:index:)` - Insert snippet at index
- `removeSnippet(_:)` - Remove snippet from folder
- `create() -> CPYFolder` - Create new folder
- `merge()` - Save folder to database
- `remove()` - Delete folder from database
- `rearrangesIndex(_:)` - Rearrange folder indices
- `rearrangesSnippetIndex()` - Rearrange snippet indices

### CPYSnippet.swift
**Text snippet model**

#### Classes
- `CPYSnippet: Object` (Realm)

#### Key Properties
- `index`, `enable`, `title`, `content`, `identifier`, `folders`

#### Key Functions
- `primaryKey() -> String?` - Realm primary key
- `ignoredProperties() -> [String]` - Realm ignored properties
- `merge()` - Save snippet to database
- `remove()` - Delete snippet from database

---

## Services

### AccessibilityService.swift
**Accessibility permission management**

#### Classes
- `AccessibilityService`

#### Key Functions
- `isAccessibilityEnabled(isPrompt:) -> Bool` - Check accessibility permission
- `showAccessibilityAuthenticationAlert()` - Show permission alert
- `openAccessibilitySettingWindow() -> Bool` - Open system preferences

### ClipService.swift
**Clipboard monitoring and management**

#### Classes
- `ClipService`

#### Key Functions
- `startMonitoring()` - Begin clipboard monitoring
- `clearAll()` - Clear all clipboard history
- `delete(with:)` - Delete specific clip
- `incrementChangeCount()` - Increment change count
- `create()` - Create clip from pasteboard
- `create(with:)` - Create clip from image
- `save(with:)` - Save clip data
- `types(with:) -> [NSPasteboard.PasteboardType]` - Get saveable types
- `canSave(with:) -> Bool` - Check if type can be saved

### DataCleanService.swift
**Data cleanup and maintenance**

#### Classes
- `DataCleanService`

#### Key Functions
- `startMonitoring()` - Begin cleanup monitoring
- `cleanDatas()` - Clean expired data
- `overflowingClips(with:) -> Results<CPYClip>` - Find clips to delete
- `cleanFiles(with:)` - Clean orphaned files

### ExcludeAppService.swift
**Application exclusion management**

#### Classes
- `ExcludeAppService`

#### Key Functions
- `init(applications:)` - Initialize with excluded apps
- `startMonitoring()` - Begin app monitoring
- `frontProcessIsExcludedApplication() -> Bool` - Check if front app excluded
- `add(with:)` - Add app to exclusion list
- `delete(with:)` - Remove app from exclusion list
- `copiedProcessIsExcludedApplications(pasteboard:) -> Bool` - Check special app exclusions

### HotKeyService.swift
**Hotkey registration and management**

#### Classes
- `HotKeyService: NSObject`

#### Key Properties
- `defaultKeyCombos` - Default hotkey combinations
- `mainKeyCombo`, `historyKeyCombo`, `snippetKeyCombo`, `clearHistoryKeyCombo`

#### Key Functions
- `popupMainMenu()` - Show main menu
- `popupHistoryMenu()` - Show history menu
- `popUpSnippetMenu()` - Show snippet menu
- `popUpClearHistoryAlert()` - Show clear history alert
- `setupDefaultHotKeys()` - Setup default hotkeys
- `change(with:keyCombo:)` - Change menu hotkey
- `changeClearHistoryKeyCombo(_:)` - Change clear history hotkey
- `register(with:keyCombo:)` - Register hotkey
- `migrationKeyCombos()` - Migrate from old framework
- `snippetKeyCombo(forIdentifier:) -> KeyCombo?` - Get snippet hotkey
- `registerSnippetHotKey(with:keyCombo:)` - Register snippet hotkey
- `unregisterSnippetHotKey(with:)` - Unregister snippet hotkey
- `popupSnippetFolder(_:)` - Show snippet folder menu

### PasteService.swift
**Paste operation management**

#### Classes
- `PasteService`

#### Key Functions
- `paste(with:)` - Paste clip content
- `copyToPasteboard(with:)` - Copy string to pasteboard
- `copyToPasteboard(with:)` - Copy clip to pasteboard
- `paste()` - Execute paste command

---

## Managers

### MenuManager.swift
**Menu creation and management**

#### Classes
- `MenuManager: NSObject`

#### Enums
- `StatusType: Int` - none, black, white

#### Key Functions
- `init()` - Initialize manager
- `setup()` - Setup manager
- `popUpMenu(_:)` - Show popup menu
- `popUpSnippetFolder(_:)` - Show snippet folder menu
- `bind()` - Bind reactive observers
- `createClipMenu()` - Create clipboard menu
- `menuItemTitle(_:listNumber:isMarkWithNumber:) -> String` - Format menu title
- `makeSubmenuItem(_:start:end:numberOfItems:) -> NSMenuItem` - Create submenu
- `incrementListNumber(_:max:start:) -> NSInteger` - Increment list number
- `trimTitle(_:) -> String` - Trim menu title
- `addHistoryItems(_:)` - Add history items to menu
- `makeClipMenuItem(_:index:listNumber:) -> NSMenuItem` - Create clip menu item
- `addSnippetItems(_:separateMenu:)` - Add snippet items to menu
- `makeSnippetMenuItem(_:listNumber:) -> NSMenuItem` - Create snippet menu item
- `changeStatusItem(_:)` - Change status bar item
- `removeStatusItem()` - Remove status bar item
- `firstIndexOfMenuItems() -> NSInteger` - Get first menu index

---

## Preferences

### CPYPreferencesWindowController.swift
**Main preferences window controller**

#### Classes
- `CPYPreferencesWindowController: NSWindowController`

#### Key Functions
- `windowDidLoad()` - Setup window
- `showWindow(_:)` - Show preferences window
- `toolBarItemTapped(_:)` - Handle toolbar selection
- `windowWillClose(_:)` - Handle window closing
- `resetImages()` - Reset toolbar images
- `selectedTab(_:)` - Update selected tab appearance
- `switchView(_:)` - Switch preference view

### Preference Panel Controllers

#### CPYBetaPreferenceViewController.swift
- `CPYBetaPreferenceViewController: NSViewController` - Beta features panel

#### CPYExcludeAppPreferenceViewController.swift
- `CPYExcludeAppPreferenceViewController: NSViewController` - App exclusion panel
- `addAppButtonTapped(_:)` - Add excluded app
- `deleteAppButtonTapped(_:)` - Remove excluded app
- `numberOfRows(in:) -> Int` - Table data source
- `tableView(_:objectValueFor:row:) -> Any?` - Table cell values

#### CPYShortcutsPreferenceViewController.swift
- `CPYShortcutsPreferenceViewController: NSViewController` - Shortcuts panel
- `loadView()` - Setup shortcuts view
- `prepareHotKeys()` - Load current hotkeys
- `recordViewShouldBeginRecording(_:) -> Bool` - Allow recording
- `recordView(_:canRecordKeyCombo:) -> Bool` - Validate key combo
- `recordView(_:didChangeKeyCombo:)` - Handle key combo change

#### CPYTypePreferenceViewController.swift
- `CPYTypePreferenceViewController: NSViewController` - Data types panel
- `loadView()` - Load store types settings

#### CPYUpdatesPreferenceViewController.swift
- `CPYUpdatesPreferenceViewController: NSViewController` - Updates panel
- `loadView()` - Setup version display

---

## Snippet Editor

### CPYSnippetsEditorWindowController.swift
**Snippet editor window controller**

#### Classes
- `CPYSnippetsEditorWindowController: NSWindowController`

#### Key Functions
- `windowDidLoad()` - Setup editor window
- `showWindow(_:)` - Show editor window
- `addSnippetButtonTapped(_:)` - Add new snippet
- `addFolderButtonTapped(_:)` - Add new folder
- `deleteButtonTapped(_:)` - Delete selected item
- `changeStatusButtonTapped(_:)` - Toggle item status
- `importSnippetButtonTapped(_:)` - Import snippets from XML
- `exportSnippetButtonTapped(_:)` - Export snippets to XML
- `changeItemFocus()` - Update UI for selected item

#### Delegate Implementations
- `NSSplitViewDelegate` - Split view constraints
- `NSOutlineViewDataSource` - Outline view data
- `NSOutlineViewDelegate` - Outline view behavior
- `NSTextViewDelegate` - Text editing
- `RecordViewDelegate` - Hotkey recording

---

## Utility Classes

### CPYUtilities.swift
**Application utilities**

#### Classes
- `CPYUtilities`

#### Key Functions
- `initSDKs()` - Initialize third-party SDKs
- `registerUserDefaultKeys()` - Register default UserDefaults values
- `applicationSupportFolder() -> String` - Get app support directory
- `prepareSaveToPath(_:) -> Bool` - Ensure directory exists
- `deleteData(at:)` - Delete file at path
- `sendCustomLog(with:)` - Send custom log event

---

## Custom Views

### CPYDesignableButton.swift
**Custom button with text color**

#### Classes
- `CPYDesignableButton: NSButton`

#### Key Functions
- `init(frame:)` - Initialize button
- `init?(coder:)` - Initialize from coder
- `initView()` - Setup button appearance

### CPYDesignableView.swift
**Custom view with border and background**

#### Classes
- `CPYDesignableView: NSView`

#### Key Properties
- `backgroundColor`, `borderColor`, `borderWidth`, `cornerRadius`

#### Key Functions
- `init(frame:)` - Initialize view
- `init?(coder:)` - Initialize from coder
- `draw(_:)` - Custom drawing

### CPYSplitView.swift
**Custom split view with separator color**

#### Classes
- `CPYSplitView: NSSplitView`

#### Key Functions
- `drawDivider(in:)` - Custom divider drawing

### CPYSnippetsEditorCell.swift
**Custom table cell for snippet editor**

#### Classes
- `CPYSnippetsEditorCell: NSTextFieldCell`

#### Enums
- `IconType` - folder, none

#### Key Functions
- `init(coder:)` - Initialize cell
- `copy(with:) -> Any` - Copy cell
- `draw(withFrame:in:)` - Custom cell drawing
- `select(withFrame:in:editor:delegate:start:length:)` - Text selection
- `edit(withFrame:in:editor:delegate:event:)` - Text editing
- `titleRect(forBounds:) -> NSRect` - Text area calculation

### CPYPlaceHolderTextView.swift
**Text view with placeholder text**

#### Classes
- `CPYPlaceHolderTextView: NSTextView`

#### Key Properties
- `placeHolderColor`, `placeHolderText`

#### Key Functions
- `draw(_:)` - Custom placeholder drawing

---

## Architecture Summary

### Key Patterns Used
1. **MVVM Architecture** - Models, Views, and ViewModels separated
2. **Dependency Injection** - Environment-based service injection
3. **Reactive Programming** - RxSwift for data binding
4. **Protocol-Oriented Design** - Extensive use of protocols and extensions
5. **Realm Database** - Object-relational mapping for persistence
6. **Command Pattern** - Menu actions and hotkey handling

### Core Components
1. **Clipboard Monitoring** - Real-time pasteboard observation
2. **Data Persistence** - Realm database with migration support
3. **Menu Management** - Dynamic menu creation and updates
4. **Hotkey System** - Global hotkey registration and handling
5. **Snippet Management** - Text snippet organization and editing
6. **Preference System** - Multi-panel preferences with data binding
7. **Import/Export** - XML-based snippet backup and restore

### Service Layer
- **ClipService** - Clipboard data management
- **MenuManager** - Menu creation and display
- **HotKeyService** - Global hotkey management
- **PasteService** - Paste operation handling
- **DataCleanService** - Cleanup and maintenance
- **ExcludeAppService** - Application filtering
- **AccessibilityService** - Permission management

This comprehensive function summary covers all major components, classes, and methods in the Clipy application codebase, providing a complete overview of the application's functionality and architecture.
import Foundation
import Cocoa
import AudioToolbox

// MARK: - ClipService
class ClipService: NSObject {
    static let shared = ClipService()
    
    private var clips: [CPYClip] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let lock = NSLock(name: "ClipService")
    
    private override init() {
        super.init()
        loadClipsFromDisk()
    }
    
    func startMonitoring() {
        let pasteboard = NSPasteboard.general
        lastChangeCount = pasteboard.changeCount
        let interval = UserDefaults.standard.double(forKey: Constants.UserDefaults.timeInterval)
        let actualInterval = interval > 0 ? interval : 0.5
        
        
        
        // Stop any existing timer
        timer?.invalidate()
        
        // Create and schedule timer on main run loop
        timer = Timer(timeInterval: actualInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        // Perform initial clipboard check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            handleClipboardChange()
        }
    }
    
    private func handleClipboardChange() {
        let pasteboard = NSPasteboard.general
        
        // Safely get pasteboard types
        guard let pasteboardTypes = pasteboard.types else {
            return
        }
        
        let availableTypes = pasteboardTypes.filter { CPYClipData.availableTypes.contains($0) }
        guard !availableTypes.isEmpty else { 
            return 
        }
        
        // Check if we should exclude this app
        if shouldExcludeCurrentApp() { 
            return 
        }
        
        // Create clip data with error handling
        let clipData: CPYClipData
        do {
            clipData = try createClipDataSafely(pasteboard: pasteboard, types: availableTypes)
        } catch {
            return
        }
        
        // Check for duplicates
        lock.lock()
        let isDuplicate = clips.contains(where: { $0.dataHash == clipData.hash })
        lock.unlock()
        
        if isDuplicate {
            return
        }
        
        // Create clip object
        let clip = CPYClip(identifier: UUID().uuidString, clipData: clipData)
        
        lock.lock()
        defer { lock.unlock() }
        
        clips.insert(clip, at: 0)
        
        // Limit history size
        let maxSize = UserDefaults.standard.integer(forKey: Constants.UserDefaults.maxHistorySize)
        let effectiveMaxSize = maxSize > 0 ? maxSize : 20 // Default to 20 if not set or 0
        if clips.count > effectiveMaxSize {
            let clipsToRemove = clips.suffix(clips.count - effectiveMaxSize)
            for clip in clipsToRemove {
                deleteClipFiles(clip)
            }
            clips = Array(clips.prefix(effectiveMaxSize))
        }
        
        saveClipsToDisk()
        playSoundEffect()
        
        // Post notification on main thread
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Constants.Notification.clipDataUpdated, object: nil)
        }
    }
    
    private func createClipDataSafely(pasteboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) throws -> CPYClipData {
        return CPYClipData(pasteboard: pasteboard, types: types)
    }
    
    func getAllClips() -> [CPYClip] {
        lock.lock()
        defer { lock.unlock() }
        return clips
    }
    
    func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        
        for clip in clips {
            deleteClipFiles(clip)
        }
        clips.removeAll()
        saveClipsToDisk()
        
        NotificationCenter.default.post(name: Constants.Notification.clipDataUpdated, object: nil)
    }
    
    func delete(clip: CPYClip) {
        lock.lock()
        defer { lock.unlock() }
        
        clips.removeObject(clip)
        deleteClipFiles(clip)
        saveClipsToDisk()
        
        NotificationCenter.default.post(name: Constants.Notification.clipDataUpdated, object: nil)
    }
    
    private func shouldExcludeCurrentApp() -> Bool {
        guard let currentApp = NSWorkspace.shared.frontmostApplication,
              let bundleIdentifier = currentApp.bundleIdentifier else { 
            return false 
        }
        
        let excludedApps = UserDefaults.standard.array(forKey: Constants.UserDefaults.excludedApplicationIdentifiers) as? [String] ?? []
        return excludedApps.contains(bundleIdentifier)
    }
    
    private func deleteClipFiles(_ clip: CPYClip) {
        try? FileManager.default.removeItem(atPath: clip.dataPath)
        if let thumbnailPath = clip.thumbnailPath {
            try? FileManager.default.removeItem(atPath: thumbnailPath)
        }
    }
    
    private func playSoundEffect() {
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaults.soundEffectEnabled) else { 
            print("Sound effects disabled")
            return 
        }
        
        let soundTypeString = UserDefaults.standard.string(forKey: Constants.UserDefaults.soundEffectType) ?? Constants.SoundEffect.sms
        let soundType = CPYSoundEffectType(rawValue: soundTypeString) ?? .sms
        
        print("Playing sound effect: \(soundType.rawValue) with ID: \(soundType.systemSoundID)")
        
        // Only play sound if it's not set to none
        if soundType != .none {
            // Use NSSound as it works better than AudioServicesPlaySystemSound
            let soundName: String
            switch soundType {
            case .sms:
                soundName = "Pop"  // Changed to Pop sound
            case .pop:
                soundName = "Pop"
            case .beep:
                soundName = "Basso"
            case .click:
                soundName = "Frog"
            case .tick:
                soundName = "Tink"
            case .bell:
                soundName = "Glass"
            case .chime:
                soundName = "Purr"
            case .whistle:
                soundName = "Submarine"
            default:
                soundName = "Pop"  // Default to Pop
            }
            
            if let sound = NSSound(named: soundName) {
                sound.play()
            } else {
                // Fall back to AudioServicesPlaySystemSound if NSSound fails
                AudioServicesPlaySystemSound(soundType.systemSoundID)
            }
        }
    }
    
    // MARK: - Sound Effect Testing
    static func playSoundEffectPreview(_ type: CPYSoundEffectType) {
        // Play sound using NSSound for preview
        let soundName: String
        switch type {
        case .sms:
            soundName = "Pop"   // Use Pop sound for SMS preview
        case .pop:
            soundName = "Pop"
        case .beep:
            soundName = "Basso"
        case .click:
            soundName = "Frog"
        case .tick:
            soundName = "Tink"
        case .bell:
            soundName = "Glass"
        case .chime:
            soundName = "Purr"
        case .whistle:
            soundName = "Submarine"
        case .none:
            return  // No sound for none
        }
        
        if let sound = NSSound(named: soundName) {
            sound.play()
        } else {
            // Fall back to AudioServicesPlaySystemSound if NSSound fails
            if type != .none {
                AudioServicesPlaySystemSound(type.systemSoundID)
            }
        }
    }
    
    private func saveClipsToDisk() {
        let clipsData = clips.map { clip in
            return [
                "identifier": clip.identifier,
                "title": clip.title,
                "dataHash": clip.dataHash,
                "primaryType": clip.primaryType.rawValue,
                "updateTime": clip.updateTime,
                "isColorCode": clip.isColorCode
            ]
        }
        
        let plistPath = "\(CPYUtilities.applicationSupportFolder())/clips.plist"
        (clipsData as NSArray).write(toFile: plistPath, atomically: true)
    }
    
    private func loadClipsFromDisk() {
        let plistPath = "\(CPYUtilities.applicationSupportFolder())/clips.plist"
        guard let clipsData = NSArray(contentsOfFile: plistPath) as? [[String: Any]] else { return }
        
        // Create a temporary array to hold clips while we load them
        var loadedClips: [CPYClip] = []
        
        for clipDict in clipsData {
            guard let identifier = clipDict["identifier"] as? String,
                  let title = clipDict["title"] as? String,
                  let dataHash = clipDict["dataHash"] as? Int,
                  let primaryTypeString = clipDict["primaryType"] as? String,
                  let updateTime = clipDict["updateTime"] as? Date,
                  let isColorCode = clipDict["isColorCode"] as? Bool else { continue }
            
            let dataPath = "\(CPYUtilities.applicationSupportFolder())/\(identifier).data"
            let thumbnailPath = "\(CPYUtilities.applicationSupportFolder())/\(identifier)_thumb.tiff"
            
            // Check if the data file exists
            guard FileManager.default.fileExists(atPath: dataPath) else { continue }
            
            // Try to load the actual clip data to verify it's valid
            guard let data = NSData(contentsOfFile: dataPath) else { continue }
            
            // Try to unarchive the clip data to verify it's valid
            let clipData: CPYClipData?
            if #available(macOS 10.13, *) {
                let unarchiver = NSKeyedUnarchiver(forReadingWith: data as Data)
                unarchiver.requiresSecureCoding = false
                do {
                    clipData = unarchiver.decodeObject(of: CPYClipData.self, forKey: NSKeyedArchiveRootObjectKey)
                    unarchiver.finishDecoding()
                } catch {
                    // Skip clips that can't be unarchived
                    continue
                }
            } else {
                clipData = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? CPYClipData
            }
            
            // Skip if we couldn't unarchive the data
            guard let validClipData = clipData else { 
                continue 
            }
            
            // Create a new CPYClip with the valid clip data
            let clip = CPYClip(identifier: identifier, clipData: validClipData)
            
            // Override the properties to match the loaded data from the plist
            // This ensures we use the correct values that were stored in the plist
            clip.title = title
            clip.updateTime = updateTime
            
            // Use the variables to avoid warnings
            _ = dataHash
            _ = primaryTypeString
            _ = isColorCode
            _ = thumbnailPath
            
            loadedClips.append(clip)
        }
        
        // Sort clips by update time (newest first)
        loadedClips.sort { $0.updateTime > $1.updateTime }
        
        // Assign to the main clips array
        lock.lock()
        clips = loadedClips
        lock.unlock()
    }
}

// MARK: - MenuManager
class MenuManager: NSObject {
    static let shared = MenuManager()
    
    private var historyMenu: NSMenu?
    private var snippetMenu: NSMenu?
    
    private override init() {
        super.init()
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipDataUpdated),
            name: Constants.Notification.clipDataUpdated,
            object: nil
        )
    }
    
    @objc private func clipDataUpdated() {
        print("Clip data updated notification received")
        updateMenus()
    }
    
    func createHistoryMenu() -> NSMenu {
        let menu = NSMenu(title: "History")
        menu.autoenablesItems = false
        historyMenu = menu
        updateHistoryMenu()
        return menu
    }
    
    func createSnippetMenu() -> NSMenu {
        let menu = NSMenu(title: "Snippets")
        menu.autoenablesItems = false
        snippetMenu = menu
        updateSnippetMenu()
        return menu
    }
    
    private func updateMenus() {
        updateHistoryMenu()
        updateSnippetMenu()
    }
    
    private func updateHistoryMenu() {
        guard let menu = historyMenu else { return }
        
        menu.removeAllItems()
        
        let clips = ClipService.shared.getAllClips()
        let numberOfRecentItems = UserDefaults.standard.integer(forKey: Constants.UserDefaults.numberOfRecentItemsToShow)
        
        // Skip the items that are shown in the main menu
        let clipsBeyondRecent = Array(clips.dropFirst(max(0, numberOfRecentItems)))
        
        if clipsBeyondRecent.isEmpty {
            let emptyItem = NSMenuItem(title: "No more clipboard history", action: nil)
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            // Take only items beyond the recent items (up to 90 items for grouping)
            let clipsToShow = Array(clipsBeyondRecent.prefix(90))
            
            // Group these items into groups of 10, with at most 9 groups
            let itemsPerGroup = 10
            let maxGroups = 9 // For items beyond recent items
            
            for groupIndex in 0..<maxGroups {
                let startIndex = groupIndex * itemsPerGroup
                let endIndex = min(startIndex + itemsPerGroup, clipsToShow.count)
                
                // Only create a group if there are items in it
                if startIndex < clipsToShow.count {
                    let groupClips = Array(clipsToShow[startIndex..<endIndex])
                    
                    // Create a submenu for this group
                    let groupMenu = NSMenu(title: "Items \(numberOfRecentItems + 1 + startIndex)-\(numberOfRecentItems + endIndex)")
                    for (index, clip) in groupClips.enumerated() {
                        let menuItem = createMenuItem(for: clip, index: numberOfRecentItems + startIndex + index) // Adjust index
                        groupMenu.addItem(menuItem)
                    }
                    
                    // Add the group submenu to the main history menu
                    let groupItem = NSMenuItem(title: "Items \(numberOfRecentItems + 1 + startIndex)-\(numberOfRecentItems + endIndex)", action: nil)
                    groupItem.submenu = groupMenu
                    menu.addItem(groupItem)
                }
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear History", action: #selector(AppDelegate.clearAllHistory)))
    }
    
    private func updateSnippetMenu() {
        guard let menu = snippetMenu else { return }
        
        menu.removeAllItems()
        
        let snippets = SnippetService.shared.getAllSnippets()
        
        if snippets.isEmpty {
            let emptyItem = NSMenuItem(title: "No snippets", action: nil)
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for snippet in snippets {
                let menuItem = createMenuItem(for: snippet)
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Edit Snippets...", action: #selector(AppDelegate.showSnippetEditorWindow)))
    }
    
    private func createMenuItem(for clip: CPYClip, index: Int) -> NSMenuItem {
        // Always use the AppDelegate's createMenuItem method to ensure consistent behavior
        if let appDelegate = NSApp.delegate as? AppDelegate {
            return appDelegate.createMenuItem(for: clip, index: index)
        }
        
        // Fallback to creating the menu item directly if we can't get the AppDelegate
        // This ensures the menu item will still work even if there's an issue with the delegate
        let maxLength = UserDefaults.standard.integer(forKey: Constants.UserDefaults.maxMenuItemTitleLength)
        let title = clip.title.count > maxLength ? String(clip.title.prefix(maxLength)) + "..." : clip.title
        
        let menuItem = NSMenuItem(title: title, action: #selector(AppDelegate.selectClipMenuItem(_:)))
        menuItem.representedObject = clip
        menuItem.target = NSApp.delegate ?? self
        
        // Add numeric key equivalent
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.addNumericKeyEquivalents) && index < 10 {
            let startWithZero = UserDefaults.standard.bool(forKey: Constants.UserDefaults.menuItemsTitleStartWithZero)
            let keyEquivalent = startWithZero ? "\(index)" : "\((index + 1) % 10)"
            menuItem.keyEquivalent = keyEquivalent
        }
        
        // Add image if available
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.showImageInTheMenu),
           let thumbnailPath = clip.thumbnailPath,
           let image = NSImage(contentsOfFile: thumbnailPath) {
            let iconSize = UserDefaults.standard.integer(forKey: Constants.UserDefaults.menuIconSize)
            menuItem.image = image.resizeImage(CGFloat(iconSize), CGFloat(iconSize))
        }
        
        return menuItem
    }
    
    private func createMenuItem(for snippet: CPYSnippet) -> NSMenuItem {
        // Use the AppDelegate's createSnippetMenuItem method to ensure consistent behavior
        if let appDelegate = NSApp.delegate as? AppDelegate {
            return appDelegate.createSnippetMenuItem(for: snippet)
        }
        
        // Fallback to creating the menu item directly if we can't get the AppDelegate
        let menuItem = NSMenuItem(title: snippet.title, action: #selector(AppDelegate.selectSnippetMenuItem(_:)))
        menuItem.representedObject = snippet
        menuItem.target = NSApp.delegate
        menuItem.isEnabled = snippet.enable
        return menuItem
    }
}

// MARK: - SnippetService
class SnippetService: NSObject {
    static let shared = SnippetService()
    
    private var folders: [CPYFolder] = []
    
    private override init() {
        super.init()
        print("DEBUG: SnippetService init() started")
        loadSnippetsFromDisk()
        print("DEBUG: SnippetService init() completed")
    }
    
    func getAllSnippets() -> [CPYSnippet] {
        return folders.flatMap { $0.snippets }.filter { $0.enable }
    }
    
    func getAllFolders() -> [CPYFolder] {
        return folders
    }
    
    func createFolder(title: String) -> CPYFolder {
        let folder = CPYFolder(title: title)
        folder.index = folders.count
        folders.append(folder)
        saveSnippetsToDisk()
        return folder
    }
    
    func deleteFolder(_ folder: CPYFolder) {
        folders.removeObject(folder)
        rearrangeFolderIndices()
        saveSnippetsToDisk()
    }
    
    func createSnippet(in folder: CPYFolder, title: String, content: String) -> CPYSnippet {
        let snippet = CPYSnippet(title: title, content: content)
        folder.addSnippet(snippet)
        saveSnippetsToDisk()
        return snippet
    }
    
    func deleteSnippet(_ snippet: CPYSnippet, from folder: CPYFolder) {
        folder.removeSnippet(snippet)
        saveSnippetsToDisk()
    }
    
    private func rearrangeFolderIndices() {
        for (index, folder) in folders.enumerated() {
            folder.index = index
        }
    }
    
    func saveSnippetsToDisk() {
        let foldersData = folders.map { folder in
            return [
                "identifier": folder.identifier,
                "title": folder.title,
                "enable": folder.enable,
                "index": folder.index,
                "snippets": folder.snippets.map { snippet in
                    return [
                        "identifier": snippet.identifier,
                        "title": snippet.title,
                        "content": snippet.content,
                        "enable": snippet.enable,
                        "index": snippet.index
                    ]
                }
            ]
        }
        
        let plistPath = "\(CPYUtilities.applicationSupportFolder())/snippets.plist"
        (foldersData as NSArray).write(toFile: plistPath, atomically: true)
    }
    
    private func loadSnippetsFromDisk() {
        print("DEBUG: loadSnippetsFromDisk() started")
        let plistPath = "\(CPYUtilities.applicationSupportFolder())/snippets.plist"
        print("DEBUG: Checking plist at: \(plistPath)")
        guard let foldersData = NSArray(contentsOfFile: plistPath) as? [[String: Any]] else { 
            print("DEBUG: No existing snippets plist found, creating default folder")
            // Create default folder if none exists
            let defaultFolder = CPYFolder(title: "Default")
            folders.append(defaultFolder)
            print("DEBUG: Default folder created")
            return 
        }
        
        for folderDict in foldersData {
            guard let identifier = folderDict["identifier"] as? String,
                  let title = folderDict["title"] as? String,
                  let enable = folderDict["enable"] as? Bool,
                  let index = folderDict["index"] as? Int,
                  let snippetsData = folderDict["snippets"] as? [[String: Any]] else { continue }
            
            let folder = CPYFolder(identifier: identifier, title: title)
            folder.enable = enable
            folder.index = index
            
            for snippetDict in snippetsData {
                guard let identifier = snippetDict["identifier"] as? String,
                      let snippetTitle = snippetDict["title"] as? String,
                      let content = snippetDict["content"] as? String,
                      let snippetEnable = snippetDict["enable"] as? Bool,
                      let snippetIndex = snippetDict["index"] as? Int else { continue }
                
                let snippet = CPYSnippet(identifier: identifier, title: snippetTitle, content: content)
                snippet.enable = snippetEnable
                snippet.index = snippetIndex
                folder.snippets.append(snippet)
            }
            
            folders.append(folder)
        }
        
        folders.sort { $0.index < $1.index }
    }
}

// MARK: - PasteService
class PasteService: NSObject {
    static let shared = PasteService()
    
    func paste(clip: CPYClip) {
        guard let clipData = clip.clipData else {
            print("DEBUG: No clip data found")
            return
        }
        
        guard let stringValue = clipData.stringValue else {
            print("DEBUG: No string value in clip data")
            return
        }
        
        print("DEBUG: Attempting to paste clip: \(clip.title)")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        _ = pasteboard.setString(stringValue, forType: .string)
        
        // Verify the content was set correctly
        let retrievedString = pasteboard.string(forType: .string)
        if retrievedString == stringValue {
            print("DEBUG: Clipboard content set successfully, triggering paste")
            // Now paste the content to the focused application
            performPasteToFocusedApp()
        } else {
            print("DEBUG: Failed to set clipboard content")
        }
    }
    
    func paste(snippet: CPYSnippet) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        _ = pasteboard.setString(snippet.content, forType: .string)
        
        // Verify the content was set correctly
        let retrievedString = pasteboard.string(forType: .string)
        if retrievedString == snippet.content {
            // Now paste the content to the focused application
            performPasteToFocusedApp()
        }
    }
    
    private func performPasteToFocusedApp() {
        print("DEBUG: performPasteToFocusedApp called")
        
        // Check if we have accessibility permissions before proceeding
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        // After rebuild, permissions may need to be re-granted due to code signature changes
        // Check if this is a fresh build by looking for signature differences
        let isRebuiltApp = checkIfAppWasRecentlyRebuilt()
        
        // Detect if launched via open command
        let launchInfo = ProcessInfo.processInfo
        let isLaunchedViaOpen = launchInfo.environment["__CFBundleIdentifier"] != nil || 
                               launchInfo.arguments.contains { $0.contains("open") } ||
                               launchInfo.environment["LAUNCH_METHOD"] == "open"
        
        print("DEBUG: Current accessibility permissions status: \(accessibilityEnabled)")
        print("DEBUG: Launched via open command: \(isLaunchedViaOpen)")
        print("DEBUG: App was recently rebuilt: \(isRebuiltApp)")
        
        // If launched via open and we don't have full permissions, we'll still try all methods
        if isLaunchedViaOpen && !accessibilityEnabled {
            print("DEBUG: Open command launch detected without full permissions - will try all available methods")
        }
        
        // If app was recently rebuilt, permissions may have been lost due to signature change
        if isRebuiltApp && !accessibilityEnabled {
            print("DEBUG: Recently rebuilt app without accessibility permissions - showing permission guidance")
            showPermissionGuidanceForRebuiltApp()
        }
        
        // Try AppleScript method first (if permissions are granted)
        if accessibilityEnabled {
            print("DEBUG: Trying AppleScript method")
            if performPasteWithAppleScript() {
                print("DEBUG: AppleScript method successful")
                return
            } else {
                print("DEBUG: AppleScript method failed")
            }
        } else {
            print("DEBUG: Skipping AppleScript due to missing accessibility permissions")
        }
        
        // Fallback to CGEvent method
        // Hide the application to ensure the previous app regains focus
        NSApp.hide(nil)
        print("DEBUG: App hidden")
        
        // Add a longer delay to allow proper focus transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            print("DEBUG: Starting keyboard simulation")
            
            // Try multiple approaches for keyboard simulation
            
            // Method 1: HID Event Tap (most reliable)
            print("DEBUG: Trying HID Event Tap method")
            if self?.simulatePasteWithHIDEventTap() == true {
                print("DEBUG: HID Event Tap method successful")
                return
            }
            
            // Method 2: CGEvent with combined session
            print("DEBUG: Trying CGEvent combined session method")
            if self?.simulatePasteWithCGEventCombined() == true {
                print("DEBUG: CGEvent combined session method successful")
                return
            }
            
            // Method 3: Alternative timing approach
            print("DEBUG: Trying alternative timing method")
            if self?.simulatePasteWithAlternativeTiming() == true {
                print("DEBUG: Alternative timing method successful")
                return
            }
            
            // Method 4: Direct notification (last resort)
            print("DEBUG: All keyboard methods failed, showing notification")
            self?.showManualPasteNotification()
        }
    }
    
    private func performPasteWithAppleScript() -> Bool {
        print("DEBUG: Attempting AppleScript paste method")
        
        // Hide the app first to ensure focus returns to the target application
        NSApp.hide(nil)
        
        // Use a shorter delay for better responsiveness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let script = """
            tell application "System Events"
                keystroke "v" using command down
            end tell
            """
            
            var error: NSDictionary?
            guard let scriptObject = NSAppleScript(source: script) else {
                print("DEBUG: Failed to create AppleScript object, trying backup methods")
                self.performBackupPasteMethods()
                return
            }
            
            print("DEBUG: AppleScript object created, executing...")
            _ = scriptObject.executeAndReturnError(&error)
            
            if let error = error {
                print("DEBUG: AppleScript error: \(error)")
                print("DEBUG: AppleScript error number: \(error["NSAppleScriptErrorNumber"] ?? "unknown")")
                
                // If AppleScript fails, immediately try backup methods
                print("DEBUG: AppleScript failed, trying backup methods")
                self.performBackupPasteMethods()
            } else {
                print("DEBUG: AppleScript executed successfully")
            }
        }
        
        return true
    }
    
    private func performBackupPasteMethods() {
        print("DEBUG: Performing backup paste methods")
        
        // Method 1: HID Event Tap (most reliable)
        print("DEBUG: Trying HID Event Tap method")
        if simulatePasteWithHIDEventTap() {
            print("DEBUG: HID Event Tap method successful")
            return
        }
        
        // Method 2: CGEvent with combined session
        print("DEBUG: Trying CGEvent combined session method")
        if simulatePasteWithCGEventCombined() {
            print("DEBUG: CGEvent combined session method successful")
            return
        }
        
        // Method 3: Alternative timing approach
        print("DEBUG: Trying alternative timing method")
        if simulatePasteWithAlternativeTiming() {
            print("DEBUG: Alternative timing method successful")
            return
        }
        
        // Method 4: Try one more aggressive approach
        print("DEBUG: Trying final aggressive paste method")
        performAggressivePaste()
    }
    
    private func simulatePasteWithHIDEventTap() -> Bool {
        print("DEBUG: Using HID Event Tap method")
        
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            print("DEBUG: Failed to create event source")
            return false
        }
        
        guard let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            print("DEBUG: Failed to create keyboard events")
            return false
        }
        
        vKeyDown.flags = CGEventFlags.maskCommand
        vKeyUp.flags = CGEventFlags.maskCommand
        
        print("DEBUG: Posting HID events")
        vKeyDown.post(tap: CGEventTapLocation.cghidEventTap)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            vKeyUp.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        return true
    }
    
    private func simulatePasteWithCGEventCombined() -> Bool {
        print("DEBUG: Using CGEvent combined session method")
        
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            print("DEBUG: Failed to create combined session source")
            return false
        }
        
        guard let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            print("DEBUG: Failed to create keyboard events")
            return false
        }
        
        vKeyDown.flags = CGEventFlags.maskCommand
        vKeyUp.flags = CGEventFlags.maskCommand
        
        print("DEBUG: Posting CGEvent combined session events to multiple taps")
        
        // Try posting to multiple event tap locations for better compatibility
        let tapLocations: [CGEventTapLocation] = [
            .cghidEventTap,
            .cgSessionEventTap,
            .cgAnnotatedSessionEventTap
        ]
        
        for tap in tapLocations {
            vKeyDown.post(tap: tap)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            for tap in tapLocations {
                vKeyUp.post(tap: tap)
            }
        }
        
        return true
    }
    
    private func simulatePasteWithCGEventPrivate() -> Bool {
        print("DEBUG: Using CGEvent alternative session method")
        
        // Use combined session state with different timing
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            print("DEBUG: Failed to create alternative session source")
            return false
        }
        
        guard let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            print("DEBUG: Failed to create keyboard events")
            return false
        }
        
        vKeyDown.flags = CGEventFlags.maskCommand
        vKeyUp.flags = CGEventFlags.maskCommand
        
        print("DEBUG: Posting CGEvent alternative session events")
        vKeyDown.post(tap: CGEventTapLocation.cghidEventTap)
        
        // Use longer delay for this method
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            vKeyUp.post(tap: CGEventTapLocation.cghidEventTap)
        }
        
        return true
    }
    
    private func simulatePasteWithAlternativeTiming() -> Bool {
        print("DEBUG: Using alternative timing method")
        
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            print("DEBUG: Failed to create alternative session source")
            return false
        }
        
        guard let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            print("DEBUG: Failed to create keyboard events")
            return false
        }
        
        vKeyDown.flags = CGEventFlags.maskCommand
        vKeyUp.flags = CGEventFlags.maskCommand
        
        print("DEBUG: Posting CGEvent with longer delays")
        
        // Longer initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            vKeyDown.post(tap: CGEventTapLocation.cghidEventTap)
            print("DEBUG: Key down posted with delay")
            
            // Longer gap between events
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                vKeyUp.post(tap: CGEventTapLocation.cghidEventTap)
                print("DEBUG: Key up posted with delay")
            }
        }
        
        return true
    }
    
    private func performAggressivePaste() {
        print("DEBUG: Performing aggressive paste - trying multiple approaches simultaneously")
        
        // Try multiple event posting locations
        let eventSources = [
            CGEventSource(stateID: .combinedSessionState),
            CGEventSource(stateID: .hidSystemState)
        ]
        
        let eventTaps: [CGEventTapLocation] = [
            .cghidEventTap,
            .cgSessionEventTap,
            .cgAnnotatedSessionEventTap
        ]
        
        for (index, source) in eventSources.enumerated() {
            guard let source = source else { continue }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
                      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
                    return
                }
                
                keyDown.flags = .maskCommand
                keyUp.flags = .maskCommand
                
                print("DEBUG: Posting aggressive paste attempt \(index + 1)")
                
                for tap in eventTaps {
                    keyDown.post(tap: tap)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        keyUp.post(tap: tap)
                    }
                }
            }
        }
        
        // If all else fails, at least the content is in clipboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("DEBUG: All paste attempts completed. Content should be available in clipboard for manual paste.")
        }
    }
    
    private func showManualPasteNotification() {
        print("DEBUG: Showing manual paste notification")
        
        // Create a user notification
        let notification = NSUserNotification()
        notification.title = "Clipy"
        notification.informativeText = "Content copied to clipboard. Press ⌘+V to paste manually."
        notification.soundName = nil
        
        NSUserNotificationCenter.default.deliver(notification)
        
        // Also show a brief alert
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Content Copied"
            alert.informativeText = "Clipboard content updated. Press ⌘+V to paste."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    private func checkIfAppWasRecentlyRebuilt() -> Bool {
        // Check if the app bundle was created/modified recently (within last hour)
        let bundlePath = Bundle.main.bundlePath
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: bundlePath)
            if let modificationDate = attributes[.modificationDate] as? Date {
                let oneHourAgo = Date().addingTimeInterval(-3600)
                return modificationDate > oneHourAgo
            }
        } catch {
            print("DEBUG: Could not check bundle modification date: \(error)")
        }
        
        return false
    }
    
    private func showPermissionGuidanceForRebuiltApp() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Permissions Required After Rebuild"
            alert.informativeText = """
            The app was recently rebuilt and may need accessibility permissions to be re-granted.
            
            To restore paste functionality:
            1. Open System Preferences > Security & Privacy > Privacy > Accessibility
            2. Remove Clipy from the list if present
            3. Re-add Clipy by clicking the '+' button
            4. Restart Clipy for best results
            
            Content has been copied to clipboard - you can paste manually with ⌘+V.
            """
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "OK")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open System Preferences to Privacy settings
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }
    
}
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
        
        // Debug logging to file
        let debugLog = "Starting clipboard monitoring with interval: \(actualInterval)s, initial change count: \(lastChangeCount)"
        logToFile(debugLog)
        
        // Log initial pasteboard state
        if let types = pasteboard.types {
            logToFile("Initial pasteboard types: \(types)")
        }
        if let string = pasteboard.string(forType: .string) {
            logToFile("Initial pasteboard string content (first 100 chars): \(String(string.prefix(100)))")
        }
        
        // Stop any existing timer
        timer?.invalidate()
        
        // Create and schedule timer on main run loop
        timer = Timer(timeInterval: actualInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
            logToFile("Timer scheduled on main run loop")
        }
        
        // Perform initial clipboard check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkClipboard()
        }
    }
    
    private func logToFile(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        let logPath = "\(CPYUtilities.applicationSupportFolder())/debug.log"
        
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        logToFile("Checking clipboard - current: \(currentChangeCount), last: \(lastChangeCount)")
        
        // Additional debugging info
        if let types = pasteboard.types {
            logToFile("Current pasteboard types: \(types)")
        } else {
            logToFile("Could not get pasteboard types")
        }
        
        if let string = pasteboard.string(forType: .string) {
            logToFile("Current pasteboard string content (first 100 chars): \(String(string.prefix(100)))")
        } else {
            logToFile("No string content in pasteboard")
        }
        
        if currentChangeCount != lastChangeCount {
            logToFile("Clipboard change detected!")
            lastChangeCount = currentChangeCount
            handleClipboardChange()
        } else {
            logToFile("No clipboard change detected")
        }
    }
    
    private func handleClipboardChange() {
        logToFile("Handling clipboard change...")
        
        // Debug current settings
        let currentMaxSize = UserDefaults.standard.integer(forKey: Constants.UserDefaults.maxHistorySize)
        let timeInterval = UserDefaults.standard.double(forKey: Constants.UserDefaults.timeInterval)
        logToFile("Current settings - maxHistorySize: \(currentMaxSize), timeInterval: \(timeInterval)")
        
        let pasteboard = NSPasteboard.general
        
        // Safely get pasteboard types
        guard let pasteboardTypes = pasteboard.types else {
            logToFile("No pasteboard types available")
            return
        }
        
        logToFile("Available pasteboard types: \(pasteboardTypes)")
        let availableTypes = pasteboardTypes.filter { CPYClipData.availableTypes.contains($0) }
        
        logToFile("Supported types: \(availableTypes)")
        guard !availableTypes.isEmpty else { 
            logToFile("No supported types found")
            return 
        }
        
        // Check if we should exclude this app
        if shouldExcludeCurrentApp() { 
            logToFile("Current app is excluded from clipboard monitoring")
            return 
        }
        
        // Create clip data with error handling
        let clipData: CPYClipData
        do {
            clipData = try createClipDataSafely(pasteboard: pasteboard, types: availableTypes)
            logToFile("Clip data created successfully")
        } catch {
            logToFile("Error creating clip data: \(error)")
            return
        }
        
        // Check for duplicates
        lock.lock()
        let isDuplicate = clips.contains(where: { $0.dataHash == clipData.hash })
        lock.unlock()
        
        if isDuplicate {
            logToFile("Duplicate clip detected, skipping")
            return
        }
        
        logToFile("Creating new clip object")
        // Create clip object
        let clip = CPYClip(identifier: UUID().uuidString, clipData: clipData)
        
        lock.lock()
        defer { lock.unlock() }
        
        clips.insert(clip, at: 0)
        logToFile("Clip added to history, total clips: \(clips.count)")
        
        // Limit history size
        let maxSize = UserDefaults.standard.integer(forKey: Constants.UserDefaults.maxHistorySize)
        let effectiveMaxSize = maxSize > 0 ? maxSize : 20 // Default to 20 if not set or 0
        logToFile("Max history size: \(maxSize), effective: \(effectiveMaxSize)")
        if clips.count > effectiveMaxSize {
            let clipsToRemove = clips.suffix(clips.count - effectiveMaxSize)
            for clip in clipsToRemove {
                deleteClipFiles(clip)
            }
            clips = Array(clips.prefix(effectiveMaxSize))
            logToFile("History truncated to \(clips.count) clips")
        }
        
        logToFile("Saving clips to disk...")
        saveClipsToDisk()
        logToFile("Playing sound effect...")
        playSoundEffect()
        
        // Post notification on main thread
        DispatchQueue.main.async {
            self.logToFile("Posting clipDataUpdated notification")
            NotificationCenter.default.post(name: Constants.Notification.clipDataUpdated, object: nil)
        }
        logToFile("Clipboard change handling completed")
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
            logToFile("Could not get current app or bundle identifier")
            return false 
        }
        
        logToFile("Current app: \(currentApp.localizedName ?? "Unknown") (\(bundleIdentifier))")
        
        let excludedApps = UserDefaults.standard.array(forKey: Constants.UserDefaults.excludedApplicationIdentifiers) as? [String] ?? []
        let isExcluded = excludedApps.contains(bundleIdentifier)
        if isExcluded {
            logToFile("Current app is excluded: \(bundleIdentifier)")
        }
        return isExcluded
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
                    logToFile("Error unarchiving clip data: \(error) for identifier \(identifier)")
                    // Skip clips that can't be unarchived
                    continue
                }
            } else {
                clipData = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? CPYClipData
            }
            
            // Skip if we couldn't unarchive the data
            guard let validClipData = clipData else { 
                logToFile("Error unarchiving clip data: Could not decode CPYClipData for identifier \(identifier)")
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
        loadSnippetsFromDisk()
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
        let plistPath = "\(CPYUtilities.applicationSupportFolder())/snippets.plist"
        guard let foldersData = NSArray(contentsOfFile: plistPath) as? [[String: Any]] else { 
            // Create default folder if none exists
            let defaultFolder = CPYFolder(title: "Default")
            folders.append(defaultFolder)
            return 
        }
        
        for folderDict in foldersData {
            guard let _ = folderDict["identifier"] as? String,
                  let title = folderDict["title"] as? String,
                  let enable = folderDict["enable"] as? Bool,
                  let index = folderDict["index"] as? Int,
                  let snippetsData = folderDict["snippets"] as? [[String: Any]] else { continue }
            
            let folder = CPYFolder(title: title)
            folder.enable = enable
            folder.index = index
            
            for snippetDict in snippetsData {
                guard let _ = snippetDict["identifier"] as? String,
                      let snippetTitle = snippetDict["title"] as? String,
                      let content = snippetDict["content"] as? String,
                      let snippetEnable = snippetDict["enable"] as? Bool,
                      let snippetIndex = snippetDict["index"] as? Int else { continue }
                
                let snippet = CPYSnippet(title: snippetTitle, content: content)
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
        guard let clipData = clip.clipData,
              let stringValue = clipData.stringValue else { 
            return 
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(stringValue, forType: .string)
    }
    
    func paste(snippet: CPYSnippet) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(snippet.content, forType: .string)
    }
    
}
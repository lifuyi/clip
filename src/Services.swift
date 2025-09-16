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
        lastChangeCount = NSPasteboard.general.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: UserDefaults.standard.double(forKey: Constants.UserDefaults.timeInterval), repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let currentChangeCount = NSPasteboard.general.changeCount
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            handleClipboardChange()
        }
    }
    
    private func handleClipboardChange() {
        let pasteboard = NSPasteboard.general
        let availableTypes = pasteboard.types?.filter { CPYClipData.availableTypes.contains($0) } ?? []
        
        guard !availableTypes.isEmpty else { return }
        
        // Check if we should exclude this app
        if shouldExcludeCurrentApp() { return }
        
        let clipData = CPYClipData(pasteboard: pasteboard, types: availableTypes)
        
        // Check for duplicates
        if clips.contains(where: { $0.dataHash == clipData.hash }) {
            return
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        let clip = CPYClip(identifier: UUID().uuidString, clipData: clipData)
        clips.insert(clip, at: 0)
        
        // Limit history size
        let maxSize = UserDefaults.standard.integer(forKey: Constants.UserDefaults.maxHistorySize)
        if clips.count > maxSize {
            let clipsToRemove = clips.suffix(clips.count - maxSize)
            for clip in clipsToRemove {
                deleteClipFiles(clip)
            }
            clips = Array(clips.prefix(maxSize))
        }
        
        saveClipsToDisk()
        playSoundEffect()
        
        NotificationCenter.default.post(name: Constants.Notification.clipDataUpdated, object: nil)
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
              let bundleIdentifier = currentApp.bundleIdentifier else { return false }
        
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
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaults.soundEffectEnabled) else { return }
        
        let soundTypeString = UserDefaults.standard.string(forKey: Constants.UserDefaults.soundEffectType) ?? Constants.SoundEffect.pop
        let soundType = CPYSoundEffectType(rawValue: soundTypeString) ?? .pop
        
        // Only play sound if it's not set to none
        if soundType != .none {
            AudioServicesPlaySystemSound(soundType.systemSoundID)
        }
    }
    
    // MARK: - Sound Effect Testing
    static func playSoundEffectPreview(_ type: CPYSoundEffectType) {
        if type != .none {
            AudioServicesPlaySystemSound(type.systemSoundID)
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
        
        for clipDict in clipsData {
            guard let identifier = clipDict["identifier"] as? String,
                  let title = clipDict["title"] as? String,
                  let dataHash = clipDict["dataHash"] as? Int,
                  let primaryTypeString = clipDict["primaryType"] as? String,
                  let updateTime = clipDict["updateTime"] as? Date,
                  let isColorCode = clipDict["isColorCode"] as? Bool else { continue }
            
            let dataPath = "\(CPYUtilities.applicationSupportFolder())/\(identifier).data"
            guard FileManager.default.fileExists(atPath: dataPath) else { continue }
            
            // Create clip object (simplified reconstruction)
            // In a real implementation, you'd want to properly reconstruct the CPYClip
        }
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
        updateMenus()
    }
    
    func createHistoryMenu() -> NSMenu {
        let menu = NSMenu(title: "History")
        historyMenu = menu
        updateHistoryMenu()
        return menu
    }
    
    func createSnippetMenu() -> NSMenu {
        let menu = NSMenu(title: "Snippets")
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
        
        if clips.isEmpty {
            let emptyItem = NSMenuItem(title: "No clipboard history", action: nil)
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            let maxItems = UserDefaults.standard.integer(forKey: Constants.UserDefaults.numberOfItemsPlaceInline)
            let itemsToShow = Array(clips.prefix(maxItems))
            
            for (index, clip) in itemsToShow.enumerated() {
                let menuItem = createMenuItem(for: clip, index: index)
                menu.addItem(menuItem)
            }
            
            if clips.count > maxItems {
                menu.addItem(NSMenuItem.separator())
                let moreItem = NSMenuItem(title: "More...", action: #selector(AppDelegate.showMoreClips))
                menu.addItem(moreItem)
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
        let maxLength = UserDefaults.standard.integer(forKey: Constants.UserDefaults.maxMenuItemTitleLength)
        let title = clip.title.count > maxLength ? String(clip.title.prefix(maxLength)) + "..." : clip.title
        
        let menuItem = NSMenuItem(title: title, action: #selector(AppDelegate.selectClipMenuItem(_:)))
        menuItem.representedObject = clip
        
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
        let menuItem = NSMenuItem(title: snippet.title, action: #selector(AppDelegate.selectSnippetMenuItem(_:)))
        menuItem.representedObject = snippet
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
    
    private func saveSnippetsToDisk() {
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
            guard let identifier = folderDict["identifier"] as? String,
                  let title = folderDict["title"] as? String,
                  let enable = folderDict["enable"] as? Bool,
                  let index = folderDict["index"] as? Int,
                  let snippetsData = folderDict["snippets"] as? [[String: Any]] else { continue }
            
            let folder = CPYFolder(title: title)
            folder.enable = enable
            folder.index = index
            
            for snippetDict in snippetsData {
                guard let snippetId = snippetDict["identifier"] as? String,
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
        guard let clipData = clip.clipData else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var items: [NSPasteboardItem] = []
        let item = NSPasteboardItem()
        
        for type in clipData.types {
            switch type {
            case .string:
                if let string = clipData.stringValue {
                    item.setString(string, forType: type)
                }
            case .rtf:
                if let rtfData = clipData.RTFData {
                    item.setData(rtfData, forType: type)
                }
            case .pdf:
                if let pdfData = clipData.PDF {
                    item.setData(pdfData, forType: type)
                }
            case .tiff:
                if let image = clipData.image,
                   let tiffData = image.tiffRepresentation {
                    item.setData(tiffData, forType: type)
                }
            case .fileURL:
                if let urls = clipData.URLs {
                    for url in urls {
                        item.setString(url.absoluteString, forType: type)
                    }
                }
            default:
                break
            }
        }
        
        items.append(item)
        pasteboard.writeObjects(items)
        
        // Simulate paste command
        simulatePaste()
    }
    
    func paste(snippet: CPYSnippet) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(snippet.content, forType: .string)
        
        simulatePaste()
    }
    
    private func simulatePaste() {
        // Create and post a paste event
        let source = CGEventSource(stateID: .hidSystemState)
        let pasteKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        let pasteKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        pasteKeyDown?.flags = .maskCommand
        pasteKeyUp?.flags = .maskCommand
        
        pasteKeyDown?.post(tap: .cghidEventTap)
        pasteKeyUp?.post(tap: .cghidEventTap)
    }
}
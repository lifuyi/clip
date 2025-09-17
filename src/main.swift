import Foundation
import Cocoa
import AppKit
import AudioToolbox
import ApplicationServices

// Comprehensive clipboard manager application based on Clipy
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var mainMenu: NSMenu!
    private var preferencesWindowController: NSWindowController?
    private var snippetEditorWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        CPYUtilities.registerUserDefaultKeys()
        checkAccessibilityPermissions()
        setupMenuBar()
        setupServices()
        setupObservers()
        promptToAddLoginItems()
    }
    
    private func checkAccessibilityPermissions() {
        // Check if we have accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        print("DEBUG: Checking accessibility permissions...")
        print("DEBUG: AXIsProcessTrustedWithOptions returned: \(accessibilityEnabled)")
        print("DEBUG: Bundle identifier: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("DEBUG: Process ID: \(getpid())")
        
        // Check if the app was launched via "open" command (which has different permissions)
        // More reliable method to detect launch method
        let launchInfo = ProcessInfo.processInfo
        let parentProcessID = launchInfo.environment["PPID"] ?? ""
        let isLaunchedViaOpen = launchInfo.environment["__CFBundleIdentifier"] != nil || 
                               launchInfo.arguments.contains { $0.contains("open") } ||
                               parentProcessID.isEmpty == false && getParentProcessName(parentProcessID) == "open"
        print("DEBUG: Launched via open command: \(isLaunchedViaOpen)")
        print("DEBUG: Launch arguments: \(launchInfo.arguments)")
        print("DEBUG: Parent process ID: \(parentProcessID)")
        
        if !accessibilityEnabled {
            print("DEBUG: Accessibility permissions not granted - paste functionality may not work")
            
            // Show alert to user with more detailed information
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            if isLaunchedViaOpen {
                alert.informativeText = "Clipy needs accessibility permissions to paste content into other applications. When launched with 'open', additional permissions may be required.\n\nPlease:\n1. Grant access in System Preferences > Security & Privacy > Privacy > Accessibility\n2. Consider running Clipy directly from Terminal for better compatibility\n3. Restart Clipy after granting permissions"
            } else {
                alert.informativeText = "Clipy needs accessibility permissions to paste content into other applications. Please grant access in System Preferences > Security & Privacy > Privacy > Accessibility and restart Clipy."
            }
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        } else {
            print("DEBUG: Accessibility permissions granted")
            
            // Additional check: try to create a test AppleScript
            testAppleScriptPermissions()
        }
    }
    
    private func getParentProcessName(_ ppid: String) -> String? {
        guard let processID = Int32(ppid) else { return nil }
        
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-p", String(processID), "-o", "comm="]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return output
        } catch {
            print("DEBUG: Failed to get parent process name: \(error)")
            return nil
        }
    }
    
    private func testAppleScriptPermissions() {
        let testScript = """
        tell application "System Events"
            return "test"
        end tell
        """
        
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: testScript) else {
            print("DEBUG: Failed to create test AppleScript object")
            return
        }
        
        _ = scriptObject.executeAndReturnError(&error)
        
        if let error = error {
            print("DEBUG: AppleScript test failed: \(error)")
            print("DEBUG: Error code: \(error["NSAppleScriptErrorNumber"] ?? "unknown")")
            print("DEBUG: This suggests AppleEvent permissions are not properly granted")
            
            // Check if it's a specific permission error
            if let errorCode = error["NSAppleScriptErrorNumber"] as? Int, errorCode == -1744 {
                print("DEBUG: This is a specific AppleEvent permission error (-1744)")
                print("DEBUG: User may need to grant automation permissions in System Preferences")
            }
        } else {
            print("DEBUG: AppleScript test successful")
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Pre-launch setup
    }
    
    // MARK: - Setup Methods
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "📋"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            // Add some styling to the status bar button
            button.wantsLayer = true
            button.layer?.cornerRadius = 4
        }
        
        mainMenu = NSMenu(title: Constants.Application.name)
        // Add styling to the main menu
        mainMenu.autoenablesItems = false
        updateMainMenu()
        statusItem.menu = mainMenu
    }
    
    private func setupServices() {
        ClipService.shared.startMonitoring()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMainMenu),
            name: Constants.Notification.clipDataUpdated,
            object: nil
        )
    }
    
    // MARK: - Menu Management
    
    @objc func updateMainMenu() {
        mainMenu.removeAllItems()
        
        // Add main sections
        addHistorySection()
        addSnippetSection()
        addPreferencesSection()
        addApplicationSection()
    }
    
    private func addHistorySection() {
        let clips = ClipService.shared.getAllClips()
        let numberOfRecentItems = UserDefaults.standard.integer(forKey: Constants.UserDefaults.numberOfRecentItemsToShow)
        
        if clips.isEmpty {
            let emptyItem = NSMenuItem(title: "No clipboard history", action: nil)
            emptyItem.isEnabled = false
            mainMenu.addItem(emptyItem)
        } else {
            // Show recent items directly in the main menu based on the preference
            let itemsToShow = Array(clips.prefix(max(0, numberOfRecentItems)))
            
            for (index, clip) in itemsToShow.enumerated() {
                let menuItem = createMenuItem(for: clip, index: index)
                mainMenu.addItem(menuItem)
            }
            
            // If we have more items than what we show inline, add a "History" submenu for the rest
            if clips.count > numberOfRecentItems && numberOfRecentItems >= 0 {
                mainMenu.addItem(NSMenuItem.separator())
                let historySubmenu = MenuManager.shared.createHistoryMenu()
                let historyItem = NSMenuItem(title: "History", action: nil)
                historyItem.submenu = historySubmenu
                mainMenu.addItem(historyItem)
            }
        }
    }
    
    private func addSnippetSection() {
        mainMenu.addItem(NSMenuItem.separator())
        
        let snippets = SnippetService.shared.getAllSnippets()
        if snippets.isEmpty {
            let emptyItem = NSMenuItem(title: "No snippets", action: nil)
            emptyItem.isEnabled = false
            mainMenu.addItem(emptyItem)
        } else {
            let snippetSubmenu = MenuManager.shared.createSnippetMenu()
            let snippetItem = NSMenuItem(title: "Snippets", action: nil)
            snippetItem.submenu = snippetSubmenu
            mainMenu.addItem(snippetItem)
        }
    }
    
    private func addPreferencesSection() {
        mainMenu.addItem(NSMenuItem.separator())
        mainMenu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferencesWindow)))
        mainMenu.addItem(NSMenuItem(title: "Edit Snippets...", action: #selector(showSnippetEditorWindow)))
    }
    
    private func addApplicationSection() {
        mainMenu.addItem(NSMenuItem.separator())
        mainMenu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearAllHistory)))
        mainMenu.addItem(NSMenuItem(title: "About \(Constants.Application.name)", action: #selector(showAbout)))
        mainMenu.addItem(NSMenuItem(title: "Quit", action: #selector(terminate), keyEquivalent: "q"))
    }
    
    func createMenuItem(for clip: CPYClip, index: Int) -> NSMenuItem {
        let maxLength = UserDefaults.standard.integer(forKey: Constants.UserDefaults.maxMenuItemTitleLength)
        let title = clip.title.count > maxLength ? String(clip.title.prefix(maxLength)) + "..." : clip.title
        
        let menuItem = NSMenuItem(title: title, action: #selector(selectClipMenuItem(_:)))
        menuItem.representedObject = clip
        menuItem.target = self
        
        // Add numeric key equivalent
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.addNumericKeyEquivalents) && index < 10 {
            let startWithZero = UserDefaults.standard.bool(forKey: Constants.UserDefaults.menuItemsTitleStartWithZero)
            let keyEquivalent = startWithZero ? "\(index)" : "\((index + 1) % 10)"
            menuItem.keyEquivalent = keyEquivalent
            // Style the key equivalent
            menuItem.keyEquivalentModifierMask = []
        }
        
        // Add color preview for color codes
        if clip.isColorCode, UserDefaults.standard.bool(forKey: Constants.UserDefaults.showColorPreviewInMenu) {
            if let clipData = clip.clipData, let colorImage = clipData.colorCodeImage {
                menuItem.image = colorImage
            }
        }
        
        // Add a tooltip with the full content
        if let clipData = clip.clipData, let stringValue = clipData.stringValue {
            menuItem.toolTip = stringValue
        }
        
        return menuItem
    }
    
    func createSnippetMenuItem(for snippet: CPYSnippet) -> NSMenuItem {
        let menuItem = NSMenuItem(title: snippet.title, action: #selector(selectSnippetMenuItem(_:)))
        menuItem.representedObject = snippet
        menuItem.target = self
        menuItem.isEnabled = snippet.enable
        
        // Add a tooltip with the snippet content
        menuItem.toolTip = snippet.content
        
        return menuItem
    }
    
    // MARK: - Menu Actions
    
    @objc func statusBarButtonClicked() {
        // Main menu is automatically shown
    }
    
    @objc func selectClipMenuItem(_ sender: NSMenuItem) {
        guard let clip = sender.representedObject as? CPYClip else { 
            return 
        }
        PasteService.shared.paste(clip: clip)
    }
    
    @objc func selectSnippetMenuItem(_ sender: NSMenuItem) {
        guard let snippet = sender.representedObject as? CPYSnippet else { return }
        PasteService.shared.paste(snippet: snippet)
    }
    
    @objc func clearAllHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear History"
        alert.informativeText = "Are you sure you want to clear all clipboard history? This action cannot be undone."
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            ClipService.shared.clearAll()
        }
    }
    
    @objc func showPreferencesWindow() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(self)
        preferencesWindowController?.window?.makeKeyAndOrderFront(self)
    }
    
    @objc func showSnippetEditorWindow() {
        if snippetEditorWindowController == nil {
            snippetEditorWindowController = SnippetEditorWindowController()
        }
        snippetEditorWindowController?.showWindow(self)
        snippetEditorWindowController?.window?.makeKeyAndOrderFront(self)
    }
    
    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(self)
    }
    
    @objc func terminate() {
        ClipService.shared.stopMonitoring()
        NSApp.terminate(self)
    }
    
    // MARK: - Hotkey Actions
    
    @objc func popUpMainMenu() {
        statusItem.menu = mainMenu
        statusItem.button?.performClick(nil)
    }
    
    @objc func popUpHistoryMenu() {
        let historyMenu = MenuManager.shared.createHistoryMenu()
        statusItem.menu = historyMenu
        statusItem.button?.performClick(nil)
        // Restore main menu after use
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.statusItem.menu = self.mainMenu
        }
    }
    
    @objc func popUpSnippetMenu() {
        let snippetMenu = MenuManager.shared.createSnippetMenu()
        statusItem.menu = snippetMenu
        statusItem.button?.performClick(nil)
        // Restore main menu after use
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.statusItem.menu = self.mainMenu
        }
    }
    
    // MARK: - Login Items
    
    private func promptToAddLoginItems() {
        if !UserDefaults.standard.bool(forKey: "hasPromptedForLoginItems") {
            let alert = NSAlert()
            alert.messageText = "Launch at Login"
            alert.informativeText = "Would you like \(Constants.Application.name) to launch automatically when you log in?"
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            
            if alert.runModal() == .alertFirstButtonReturn {
                toggleAddingToLoginItems(true)
            }
            
            UserDefaults.standard.set(true, forKey: "hasPromptedForLoginItems")
        }
    }
    
    @objc func toggleAddingToLoginItems(_ enable: Bool) {
        // Simplified login items handling - in a full implementation you'd use proper APIs
        UserDefaults.standard.set(enable, forKey: Constants.UserDefaults.loginItem)
        
        // Note: Full login items implementation would require proper LaunchServices integration
        print("Login items setting changed to: \(enable)")
    }
    
    // MARK: - Menu Validation
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(clearAllHistory) {
            return !ClipService.shared.getAllClips().isEmpty
        }
        return true
    }
}

// Create and configure the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)

// Run the application
app.run()
import Foundation
import Cocoa
import AppKit
import AudioToolbox

// Comprehensive clipboard manager application based on Clipy
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var mainMenu: NSMenu!
    private var preferencesWindowController: NSWindowController?
    private var snippetEditorWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        CPYUtilities.registerUserDefaultKeys()
        setupMenuBar()
        setupServices()
        setupObservers()
        promptToAddLoginItems()
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
        }
        
        mainMenu = NSMenu(title: Constants.Application.name)
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
        let maxInlineItems = UserDefaults.standard.integer(forKey: Constants.UserDefaults.numberOfItemsPlaceInline)
        
        if clips.isEmpty {
            let emptyItem = NSMenuItem(title: "No clipboard history", action: nil)
            emptyItem.isEnabled = false
            mainMenu.addItem(emptyItem)
        } else {
            let itemsToShow = Array(clips.prefix(maxInlineItems))
            
            for (index, clip) in itemsToShow.enumerated() {
                let menuItem = createMenuItem(for: clip, index: index)
                mainMenu.addItem(menuItem)
            }
            
            if clips.count > maxInlineItems {
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
        }
        
        // Add color preview for color codes
        if clip.isColorCode, UserDefaults.standard.bool(forKey: Constants.UserDefaults.showColorPreviewInMenu) {
            if let clipData = clip.clipData, let colorImage = clipData.colorCodeImage {
                menuItem.image = colorImage
            }
        }
        
        return menuItem
    }
    
    func createSnippetMenuItem(for snippet: CPYSnippet) -> NSMenuItem {
        let menuItem = NSMenuItem(title: snippet.title, action: #selector(selectSnippetMenuItem(_:)))
        menuItem.representedObject = snippet
        menuItem.target = self
        menuItem.isEnabled = snippet.enable
        return menuItem
    }
    
    // MARK: - Menu Actions
    
    @objc func statusBarButtonClicked() {
        // Main menu is automatically shown
    }
    
    @objc func selectClipMenuItem(_ sender: NSMenuItem) {
        guard let clip = sender.representedObject as? CPYClip else { return }
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
    
    @objc func showMoreClips() {
        // Implementation for showing more clips in a separate window
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
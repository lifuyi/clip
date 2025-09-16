import Foundation
import Cocoa
import AppKit
import AudioToolbox

// Simple menu bar application for clipboard management
class MyClipyMenuBarApp: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var clipboardItems: [String] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        startClipboardMonitoring()
    }
    
    func setupMenuBar() {
        // Create status item with a fixed length instead of squareLength
        statusItem = NSStatusBar.system.statusItem(withLength: 24)
        
        // Set up the status bar button
        if let button = statusItem.button {
            button.title = "📋"
            button.action = #selector(statusBarButtonClicked)
        }
        
        // Create menu
        menu = NSMenu(title: "MyClipy")
        
        // Add initial menu items
        updateMenu()
        
        // Set menu for status item
        statusItem.menu = menu
    }
    
    func updateMenu() {
        // Clear existing items except for the first few
        menu.removeAllItems()
        
        // Add clipboard items
        if clipboardItems.isEmpty {
            let emptyItem = NSMenuItem(title: "No clipboard history", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            // Add all clipboard items
            for item in clipboardItems {
                let title = item.count > 30 ? String(item.prefix(30)) + "..." : item
                let menuItem = NSMenuItem(title: title, action: #selector(clipboardItemClicked(_:)), keyEquivalent: "")
                menuItem.representedObject = item
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    func startClipboardMonitoring() {
        // Get initial change count
        lastChangeCount = NSPasteboard.general.changeCount
        
        // Start timer to check for changes
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func checkClipboard() {
        let currentChangeCount = NSPasteboard.general.changeCount
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            handleClipboardChange()
        }
    }
    
    func handleClipboardChange() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            // Remove duplicates
            clipboardItems.removeAll { $0 == string }
            
            // Add new item at the beginning
            clipboardItems.insert(string, at: 0)
            
            // Retain all clipboard history (no limit)
            
            // Play sound effect
            playCopySound()
            
            // Update menu
            updateMenu()
        }
    }
    
    @objc func statusBarButtonClicked() {
        print("Status bar button clicked")
    }
    
    @objc func clipboardItemClicked(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? String else { return }
        
        // Copy to pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(item, forType: .string)
        
        // Play sound effect
        playCopySound()
        
        print("Copied to clipboard: \(item)")
    }
    
    @objc func clearHistory() {
        clipboardItems.removeAll()
        updateMenu()
        print("Clipboard history cleared")
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func playCopySound() {
        // Use the most reliable system sound
        AudioServicesPlaySystemSound(1006) // Default beep sound
    }
}

// Create and configure the application
let app = NSApplication.shared
let delegate = MyClipyMenuBarApp()
app.delegate = delegate
app.setActivationPolicy(.accessory)

// Run the application
app.run()
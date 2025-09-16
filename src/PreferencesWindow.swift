import Foundation
import Cocoa

// Simple preferences window for basic settings
class PreferencesWindowController: NSWindowController {
    
    @IBOutlet weak var maxHistorySizeField: NSTextField!
    @IBOutlet weak var soundEffectCheckbox: NSButton!
    @IBOutlet weak var soundEffectTypePopup: NSPopUpButton!
    @IBOutlet weak var showImageCheckbox: NSButton!
    @IBOutlet weak var colorPreviewCheckbox: NSButton!
    @IBOutlet weak var numericKeysCheckbox: NSButton!
    @IBOutlet weak var launchAtLoginCheckbox: NSButton!
    @IBOutlet weak var timeIntervalSlider: NSSlider!
    @IBOutlet weak var timeIntervalLabel: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setupWindow()
        loadPreferences()
    }
    
    private func setupWindow() {
        window?.title = "Preferences"
        window?.styleMask = [.titled, .closable]
        window?.isRestorable = false
        window?.center()
    }
    
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        
        maxHistorySizeField.integerValue = defaults.integer(forKey: Constants.UserDefaults.maxHistorySize)
        soundEffectCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.soundEffectEnabled) ? .on : .off
        
        // Setup sound effect type popup
        setupSoundEffectPopup()
        loadSoundEffectType()
        
        showImageCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.showImageInTheMenu) ? .on : .off
        colorPreviewCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.showColorPreviewInMenu) ? .on : .off
        numericKeysCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.addNumericKeyEquivalents) ? .on : .off
        launchAtLoginCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.loginItem) ? .on : .off
        
        let timeInterval = defaults.double(forKey: Constants.UserDefaults.timeInterval)
        timeIntervalSlider.doubleValue = timeInterval
        timeIntervalLabel.stringValue = String(format: "%.1f seconds", timeInterval)
    }
    
    @IBAction func maxHistorySizeChanged(_ sender: NSTextField) {
        let value = max(1, min(200, sender.integerValue))
        sender.integerValue = value
        UserDefaults.standard.set(value, forKey: Constants.UserDefaults.maxHistorySize)
    }
    
    @IBAction func soundEffectToggled(_ sender: NSButton) {
        let isEnabled = sender.state == .on
        UserDefaults.standard.set(isEnabled, forKey: Constants.UserDefaults.soundEffectEnabled)
        
        // Enable/disable the sound type popup based on checkbox state
        soundEffectTypePopup.isEnabled = isEnabled
    }
    
    @IBAction func soundEffectTypeChanged(_ sender: NSPopUpButton) {
        guard let selectedItem = sender.selectedItem,
              let soundType = selectedItem.representedObject as? CPYSoundEffectType else { return }
        
        UserDefaults.standard.set(soundType.rawValue, forKey: Constants.UserDefaults.soundEffectType)
        
        // Play preview of selected sound
        ClipService.playSoundEffectPreview(soundType)
    }
    
    @IBAction func showImageToggled(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Constants.UserDefaults.showImageInTheMenu)
    }
    
    @IBAction func colorPreviewToggled(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Constants.UserDefaults.showColorPreviewInMenu)
    }
    
    @IBAction func numericKeysToggled(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Constants.UserDefaults.addNumericKeyEquivalents)
    }
    
    @IBAction func launchAtLoginToggled(_ sender: NSButton) {
        let enable = sender.state == .on
        UserDefaults.standard.set(enable, forKey: Constants.UserDefaults.loginItem)
        
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.toggleAddingToLoginItems(enable)
        }
    }
    
    @IBAction func timeIntervalChanged(_ sender: NSSlider) {
        let value = sender.doubleValue
        UserDefaults.standard.set(value, forKey: Constants.UserDefaults.timeInterval)
        timeIntervalLabel.stringValue = String(format: "%.1f seconds", value)
        
        // Restart monitoring with new interval
        ClipService.shared.stopMonitoring()
        ClipService.shared.startMonitoring()
    }
    
    @IBAction func resetToDefaults(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Reset Preferences"
        alert.informativeText = "Are you sure you want to reset all preferences to their default values?"
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            resetPreferences()
        }
    }
    
    private func resetPreferences() {
        let defaults = UserDefaults.standard
        
        defaults.removeObject(forKey: Constants.UserDefaults.maxHistorySize)
        defaults.removeObject(forKey: Constants.UserDefaults.soundEffectEnabled)
        defaults.removeObject(forKey: Constants.UserDefaults.soundEffectType)
        defaults.removeObject(forKey: Constants.UserDefaults.showImageInTheMenu)
        defaults.removeObject(forKey: Constants.UserDefaults.showColorPreviewInMenu)
        defaults.removeObject(forKey: Constants.UserDefaults.addNumericKeyEquivalents)
        defaults.removeObject(forKey: Constants.UserDefaults.timeInterval)
        
        CPYUtilities.registerUserDefaultKeys()
        loadPreferences()
    }
    
    // MARK: - Sound Effect Setup
    
    private func setupSoundEffectPopup() {
        soundEffectTypePopup.removeAllItems()
        
        for soundType in CPYSoundEffectType.allCases {
            let menuItem = NSMenuItem(title: soundType.displayName, action: nil, keyEquivalent: "")
            menuItem.representedObject = soundType
            menuItem.toolTip = soundType.description
            soundEffectTypePopup.menu?.addItem(menuItem)
        }
    }
    
    private func loadSoundEffectType() {
        let defaults = UserDefaults.standard
        let soundTypeString = defaults.string(forKey: Constants.UserDefaults.soundEffectType) ?? Constants.SoundEffect.pop
        let soundType = CPYSoundEffectType(rawValue: soundTypeString) ?? .pop
        
        // Select the appropriate item in the popup
        for i in 0..<soundEffectTypePopup.numberOfItems {
            if let menuItem = soundEffectTypePopup.item(at: i),
               let itemSoundType = menuItem.representedObject as? CPYSoundEffectType,
               itemSoundType == soundType {
                soundEffectTypePopup.selectItem(at: i)
                break
            }
        }
        
        // Enable/disable popup based on checkbox state
        soundEffectTypePopup.isEnabled = defaults.bool(forKey: Constants.UserDefaults.soundEffectEnabled)
    }
}

// Simple snippet editor window
class SnippetEditorWindowController: NSWindowController {
    
    @IBOutlet weak var foldersOutlineView: NSOutlineView!
    @IBOutlet weak var snippetTitleField: NSTextField!
    @IBOutlet weak var snippetContentTextView: NSTextView!
    @IBOutlet weak var addFolderButton: NSButton!
    @IBOutlet weak var addSnippetButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    
    private var folders: [CPYFolder] = []
    private var selectedItem: Any?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setupWindow()
        setupOutlineView()
        loadData()
    }
    
    private func setupWindow() {
        window?.title = "Snippet Editor"
        window?.setContentSize(NSSize(width: 800, height: 600))
        window?.center()
    }
    
    private func setupOutlineView() {
        foldersOutlineView.dataSource = self
        foldersOutlineView.delegate = self
        foldersOutlineView.reloadData()
    }
    
    private func loadData() {
        folders = SnippetService.shared.getAllFolders()
        foldersOutlineView.reloadData()
        
        if !folders.isEmpty {
            foldersOutlineView.expandItem(nil, expandChildren: true)
        }
    }
    
    @IBAction func addFolderClicked(_ sender: NSButton) {
        let folder = SnippetService.shared.createFolder(title: "New Folder")
        folders.append(folder)
        foldersOutlineView.reloadData()
        
        let index = folders.count - 1
        foldersOutlineView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
    }
    
    @IBAction func addSnippetClicked(_ sender: NSButton) {
        guard let selectedFolder = getSelectedFolder() else {
            showAlert("Please select a folder first.")
            return
        }
        
        let snippet = SnippetService.shared.createSnippet(in: selectedFolder, title: "New Snippet", content: "")
        foldersOutlineView.reloadData()
        
        // Select the new snippet
        if let folderIndex = folders.firstIndex(of: selectedFolder) {
            foldersOutlineView.expandItem(selectedFolder)
            let snippetRow = foldersOutlineView.row(forItem: snippet)
            foldersOutlineView.selectRowIndexes(IndexSet(integer: snippetRow), byExtendingSelection: false)
        }
    }
    
    @IBAction func deleteClicked(_ sender: NSButton) {
        guard let selectedItem = selectedItem else { return }
        
        let alert = NSAlert()
        alert.messageText = "Delete Item"
        alert.informativeText = "Are you sure you want to delete this item?"
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let folder = selectedItem as? CPYFolder {
                SnippetService.shared.deleteFolder(folder)
                folders.removeObject(folder)
            } else if let snippet = selectedItem as? CPYSnippet,
                      let folder = getParentFolder(for: snippet) {
                SnippetService.shared.deleteSnippet(snippet, from: folder)
            }
            
            foldersOutlineView.reloadData()
            clearDetails()
        }
    }
    
    private func getSelectedFolder() -> CPYFolder? {
        let selectedRow = foldersOutlineView.selectedRow
        guard selectedRow >= 0 else { return nil }
        
        let item = foldersOutlineView.item(atRow: selectedRow)
        
        if let folder = item as? CPYFolder {
            return folder
        } else if let snippet = item as? CPYSnippet {
            return getParentFolder(for: snippet)
        }
        
        return nil
    }
    
    private func getParentFolder(for snippet: CPYSnippet) -> CPYFolder? {
        return folders.first { $0.snippets.contains(snippet) }
    }
    
    private func clearDetails() {
        snippetTitleField.stringValue = ""
        snippetContentTextView.string = ""
        selectedItem = nil
    }
    
    private func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - NSOutlineViewDataSource
extension SnippetEditorWindowController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return folders.count
        } else if let folder = item as? CPYFolder {
            return folder.snippets.count
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return folders[index]
        } else if let folder = item as? CPYFolder {
            return folder.snippets[index]
        }
        return NSNull()
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is CPYFolder
    }
}

// MARK: - NSOutlineViewDelegate
extension SnippetEditorWindowController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("DataCell")
        var view = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        
        if view == nil {
            view = NSTableCellView()
            view?.identifier = identifier
            
            let textField = NSTextField()
            textField.isBordered = false
            textField.backgroundColor = NSColor.clear
            textField.isEditable = false
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            view?.addSubview(textField)
            view?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: view!.leadingAnchor, constant: 2),
                textField.trailingAnchor.constraint(equalTo: view!.trailingAnchor, constant: -2),
                textField.centerYAnchor.constraint(equalTo: view!.centerYAnchor)
            ])
        }
        
        if let folder = item as? CPYFolder {
            view?.textField?.stringValue = "📁 " + folder.title
        } else if let snippet = item as? CPYSnippet {
            view?.textField?.stringValue = "📄 " + snippet.title
        }
        
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = foldersOutlineView.selectedRow
        guard selectedRow >= 0 else {
            clearDetails()
            return
        }
        
        selectedItem = foldersOutlineView.item(atRow: selectedRow)
        
        if let snippet = selectedItem as? CPYSnippet {
            snippetTitleField.stringValue = snippet.title
            snippetContentTextView.string = snippet.content
        } else {
            clearDetails()
        }
    }
}
import Foundation
import Cocoa

// Modern styled preferences window
class PreferencesWindowController: NSWindowController {
    
    private var maxHistorySizeField: NSTextField!
    private var maxMenuItemTitleLengthField: NSTextField!
    private var maxSnippetsField: NSTextField!
    private var soundEffectCheckbox: NSButton!
    private var soundEffectPopup: NSPopUpButton!
    private var showImageCheckbox: NSButton!
    private var colorPreviewCheckbox: NSButton!
    private var numericKeysCheckbox: NSButton!
    private var launchAtLoginCheckbox: NSButton!
    private var timeIntervalSlider: NSSlider!
    private var timeIntervalLabel: NSTextField!
    private var recentItemsField: NSTextField! // New field
    
    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                             styleMask: [.titled, .closable],
                             backing: .buffered,
                             defer: false)
        window.title = "Clipy Preferences"
        window.center()
        super.init(window: window)
        setupUI()
        loadPreferences()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // Main scroll view for better handling of content
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        contentView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Content view for scroll view
        let contentScrollView = NSView()
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentScrollView
        
        NSLayoutConstraint.activate([
            contentScrollView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentScrollView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Main stack view
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentScrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentScrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentScrollView.bottomAnchor, constant: -20)
        ])
        
        // Title
        let titleLabel = NSTextField(labelWithString: "Clipy Preferences")
        titleLabel.styleAsTitleLabel()
        stackView.addArrangedSubview(titleLabel)
        
        // History Settings Section
        let historyLabel = NSTextField(labelWithString: "History Settings")
        historyLabel.styleAsSectionHeader()
        stackView.addArrangedSubview(historyLabel)
        
        // Max History Size
        let historySizeView = createLabeledField("Maximum History Size:", width: 180)
        maxHistorySizeField = historySizeView.field
        maxHistorySizeField.target = self
        maxHistorySizeField.action = #selector(maxHistorySizeChanged(_:))
        stackView.addArrangedSubview(historySizeView.container)
        
        // Number of Recent Items to Show
        let recentItemsView = createLabeledField("Recent Items to Show:", width: 180)
        recentItemsField = recentItemsView.field // FIX: Assign the field property
        recentItemsView.field.integerValue = UserDefaults.standard.integer(forKey: Constants.UserDefaults.numberOfRecentItemsToShow)
        recentItemsView.field.target = self
        recentItemsView.field.action = #selector(recentItemsToShowChanged(_:))
        stackView.addArrangedSubview(recentItemsView.container)
        
        // Menu Item Title Length
        let titleLengthView = createLabeledField("Menu Title Length:", width: 180)
        maxMenuItemTitleLengthField = titleLengthView.field
        maxMenuItemTitleLengthField.target = self
        maxMenuItemTitleLengthField.action = #selector(maxMenuItemTitleLengthChanged(_:))
        stackView.addArrangedSubview(titleLengthView.container)
        
        // Max Snippets
        let maxSnippetsView = createLabeledField("Maximum Snippets:", width: 180)
        maxSnippetsField = maxSnippetsView.field
        maxSnippetsField.target = self
        maxSnippetsField.action = #selector(maxSnippetsChanged(_:))
        stackView.addArrangedSubview(maxSnippetsView.container)
        
        // Display Options Section
        let displayLabel = NSTextField(labelWithString: "Display Options")
        displayLabel.styleAsSectionHeader()
        stackView.addArrangedSubview(displayLabel)
        
        // Checkboxes with proper spacing
        showImageCheckbox = NSButton(checkboxWithTitle: "Show images in menu", target: self, action: #selector(showImageToggled(_:)))
        stackView.addArrangedSubview(showImageCheckbox)
        
        colorPreviewCheckbox = NSButton(checkboxWithTitle: "Show color preview in menu", target: self, action: #selector(colorPreviewToggled(_:)))
        stackView.addArrangedSubview(colorPreviewCheckbox)
        
        numericKeysCheckbox = NSButton(checkboxWithTitle: "Enable numeric shortcuts (0-9)", target: self, action: #selector(numericKeysToggled(_:)))
        stackView.addArrangedSubview(numericKeysCheckbox)
        
        // Sound Settings Section
        let soundLabel = NSTextField(labelWithString: "Sound Settings")
        soundLabel.styleAsSectionHeader()
        stackView.addArrangedSubview(soundLabel)
        
        soundEffectCheckbox = NSButton(checkboxWithTitle: "Enable sound effects", target: self, action: #selector(soundEffectToggled(_:)))
        stackView.addArrangedSubview(soundEffectCheckbox)
        
        // Sound Effect Type
        let soundEffectView = createSoundEffectPopup()
        soundEffectPopup = soundEffectView.popup
        soundEffectPopup.target = self
        soundEffectPopup.action = #selector(soundEffectTypeChanged(_:))
        stackView.addArrangedSubview(soundEffectView.container)
        
        // Timing Settings Section
        let timingLabel = NSTextField(labelWithString: "Timing Settings")
        timingLabel.styleAsSectionHeader()
        stackView.addArrangedSubview(timingLabel)
        
        // Time Interval
        let intervalView = createSliderField("Check Interval (seconds):", width: 180)
        timeIntervalSlider = intervalView.slider
        timeIntervalLabel = intervalView.label
        timeIntervalSlider.target = self
        timeIntervalSlider.action = #selector(timeIntervalChanged(_:))
        stackView.addArrangedSubview(intervalView.container)
        
        // Launch at Login Section
        let loginLabel = NSTextField(labelWithString: "Startup Settings")
        loginLabel.styleAsSectionHeader()
        stackView.addArrangedSubview(loginLabel)
        
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(launchAtLoginToggled(_:)))
        stackView.addArrangedSubview(launchAtLoginCheckbox)
        
        // Reset Button
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetToDefaults(_:)))
        resetButton.styleAsSecondaryButton()
        stackView.addArrangedSubview(resetButton)
    }
    
    private func createLabeledField(_ label: String, width: CGFloat) -> (container: NSView, field: NSTextField) {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        
        let labelField = NSTextField(labelWithString: label)
        labelField.translatesAutoresizingMaskIntoConstraints = false
        labelField.styleAsBodyLabel()
        
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.stringValue = "100"
        textField.styleAsTextField()
        
        container.addSubview(labelField)
        container.addSubview(textField)
        
        NSLayoutConstraint.activate([
            labelField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            labelField.widthAnchor.constraint(equalToConstant: width),
            textField.leadingAnchor.constraint(equalTo: labelField.trailingAnchor, constant: 10),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        return (container, textField)
    }
    
    private func createSoundEffectPopup() -> (container: NSView, popup: NSPopUpButton) {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        
        let labelField = NSTextField(labelWithString: "Sound Effect:")
        labelField.translatesAutoresizingMaskIntoConstraints = false
        labelField.styleAsBodyLabel()
        
        let popupButton = NSPopUpButton()
        popupButton.translatesAutoresizingMaskIntoConstraints = false
        popupButton.font = UIConstants.Typography.body
        
        // Add all available sound effects to the popup
        for soundType in CPYSoundEffectType.allCases {
            if soundType != .none {
                popupButton.addItem(withTitle: soundType.displayName)
                popupButton.lastItem?.representedObject = soundType
            }
        }
        
        container.addSubview(labelField)
        container.addSubview(popupButton)
        
        NSLayoutConstraint.activate([
            labelField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            labelField.widthAnchor.constraint(equalToConstant: 180),
            popupButton.leadingAnchor.constraint(equalTo: labelField.trailingAnchor, constant: 10),
            popupButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            popupButton.widthAnchor.constraint(equalToConstant: 150)
        ])
        
        return (container, popupButton)
    }
    
    private func createSliderField(_ label: String, width: CGFloat) -> (container: NSView, slider: NSSlider, label: NSTextField) {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        
        let labelField = NSTextField(labelWithString: label)
        labelField.translatesAutoresizingMaskIntoConstraints = false
        labelField.styleAsBodyLabel()
        
        let slider = NSSlider(value: 0.5, minValue: 0.1, maxValue: 2.0, target: nil, action: nil)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.wantsLayer = true
        slider.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        slider.layer?.cornerRadius = UIConstants.CornerRadius.small
        
        let valueLabel = NSTextField(labelWithString: "0.5")
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.styleAsBodyLabel()
        
        container.addSubview(labelField)
        container.addSubview(slider)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            labelField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            labelField.widthAnchor.constraint(equalToConstant: width),
            slider.leadingAnchor.constraint(equalTo: labelField.trailingAnchor, constant: 10),
            slider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: 120),
            valueLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 10),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        return (container, slider, valueLabel)
    }
    
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        
        maxHistorySizeField.integerValue = defaults.integer(forKey: Constants.UserDefaults.maxHistorySize)
        if maxHistorySizeField.integerValue == 0 {
            maxHistorySizeField.integerValue = 100
        }
        
        maxMenuItemTitleLengthField.integerValue = defaults.integer(forKey: Constants.UserDefaults.maxMenuItemTitleLength)
        if maxMenuItemTitleLengthField.integerValue == 0 {
            maxMenuItemTitleLengthField.integerValue = 15
        }
        
        maxSnippetsField.integerValue = defaults.integer(forKey: Constants.UserDefaults.maxSnippets)
        if maxSnippetsField.integerValue == 0 {
            maxSnippetsField.integerValue = 10
        }
        
        recentItemsField.integerValue = defaults.integer(forKey: Constants.UserDefaults.numberOfRecentItemsToShow)
        if recentItemsField.integerValue == 0 {
            recentItemsField.integerValue = 6
        }
        
        // Note: These keys might not exist yet, so we'll add basic ones
        showImageCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.showImageInTheMenu) ? .on : .off
        colorPreviewCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.showColorPreviewInMenu) ? .on : .off
        numericKeysCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.addNumericKeyEquivalents) ? .on : .off
        soundEffectCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.soundEffectEnabled) ? .on : .off
        launchAtLoginCheckbox.state = defaults.bool(forKey: Constants.UserDefaults.loginItem) ? .on : .off
        
        let timeInterval = defaults.double(forKey: Constants.UserDefaults.timeInterval)
        timeIntervalSlider?.doubleValue = timeInterval > 0 ? timeInterval : 0.5
        timeIntervalLabel?.stringValue = String(format: "%.1f", timeIntervalSlider?.doubleValue ?? 0.5)
        
        // Load sound effect type
        loadSoundEffectType()
    }
    
    private func loadSoundEffectType() {
        let defaults = UserDefaults.standard
        let soundTypeString = defaults.string(forKey: Constants.UserDefaults.soundEffectType) ?? Constants.SoundEffect.pop
        let soundType = CPYSoundEffectType(rawValue: soundTypeString) ?? .pop
        
        // Select the appropriate item in the popup
        for i in 0..<soundEffectPopup.numberOfItems {
            if let menuItem = soundEffectPopup.item(at: i),
               let itemSoundType = menuItem.representedObject as? CPYSoundEffectType,
               itemSoundType == soundType {
                soundEffectPopup.selectItem(at: i)
                break
            }
        }
        
        // Enable/disable popup based on checkbox state
        soundEffectPopup.isEnabled = defaults.bool(forKey: Constants.UserDefaults.soundEffectEnabled)
    }
    
    @objc private func maxHistorySizeChanged(_ sender: NSTextField) {
        let value = max(1, min(200, sender.integerValue))
        sender.integerValue = value
        UserDefaults.standard.set(value, forKey: Constants.UserDefaults.maxHistorySize)
    }
    
    @objc private func recentItemsToShowChanged(_ sender: NSTextField) {
        let value = max(0, min(50, sender.integerValue))
        sender.integerValue = value
        UserDefaults.standard.set(value, forKey: Constants.UserDefaults.numberOfRecentItemsToShow)
        
        // Post notification to update menus
        NotificationCenter.default.post(name: Constants.Notification.clipDataUpdated, object: nil)
    }
    
    @objc private func maxMenuItemTitleLengthChanged(_ sender: NSTextField) {
        let value = max(10, min(200, sender.integerValue))
        sender.integerValue = value
        UserDefaults.standard.set(value, forKey: Constants.UserDefaults.maxMenuItemTitleLength)
    }
    
    @objc private func maxSnippetsChanged(_ sender: NSTextField) {
        let value = max(1, min(200, sender.integerValue))
        sender.integerValue = value
        UserDefaults.standard.set(value, forKey: Constants.UserDefaults.maxSnippets)
    }
    
    @objc private func showImageToggled(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Constants.UserDefaults.showImageInTheMenu)
    }
    
    @objc private func colorPreviewToggled(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Constants.UserDefaults.showColorPreviewInMenu)
    }
    
    @objc private func numericKeysToggled(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Constants.UserDefaults.addNumericKeyEquivalents)
    }
    
    @objc private func soundEffectToggled(_ sender: NSButton) {
        let isEnabled = sender.state == .on
        UserDefaults.standard.set(isEnabled, forKey: Constants.UserDefaults.soundEffectEnabled)
        
        // Enable/disable the sound type popup based on checkbox state
        soundEffectPopup.isEnabled = isEnabled
    }
    
    @objc private func soundEffectTypeChanged(_ sender: NSPopUpButton) {
        guard let selectedItem = sender.selectedItem,
              let soundType = selectedItem.representedObject as? CPYSoundEffectType else { return }
        
        UserDefaults.standard.set(soundType.rawValue, forKey: Constants.UserDefaults.soundEffectType)
        
        // Play preview of selected sound - FIX: Dispatch to background queue
        DispatchQueue.global(qos: .userInitiated).async {
            ClipService.playSoundEffectPreview(soundType)
        }
    }
    
    @objc private func timeIntervalChanged(_ sender: NSSlider) {
        let value = sender.doubleValue
        timeIntervalLabel?.stringValue = String(format: "%.1f", value)
        UserDefaults.standard.set(value, forKey: Constants.UserDefaults.timeInterval)
    }
    
    @objc private func launchAtLoginToggled(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: Constants.UserDefaults.loginItem)
    }
    
    @objc private func resetToDefaults(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Reset Preferences"
        alert.informativeText = "Are you sure you want to reset all preferences to their default values?"
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Reset to defaults
            UserDefaults.standard.set(100, forKey: Constants.UserDefaults.maxHistorySize)
            UserDefaults.standard.set(6, forKey: Constants.UserDefaults.numberOfRecentItemsToShow)
            UserDefaults.standard.set(15, forKey: Constants.UserDefaults.maxMenuItemTitleLength)
            UserDefaults.standard.set(10, forKey: Constants.UserDefaults.maxSnippets)
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.showImageInTheMenu)
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.showColorPreviewInMenu)
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.addNumericKeyEquivalents)
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.soundEffectEnabled)
            UserDefaults.standard.set(Constants.SoundEffect.pop, forKey: Constants.UserDefaults.soundEffectType)
            UserDefaults.standard.set(0.5, forKey: Constants.UserDefaults.timeInterval)
            UserDefaults.standard.set(false, forKey: Constants.UserDefaults.loginItem)
            
            loadPreferences()
        }
    }
}

// MARK: - SnippetEditorWindowController with Critical Fixes

class SnippetEditorWindowController: NSWindowController {
    private var snippetTableView: NSTableView!
    private var folderPopupButton: NSPopUpButton!
    private var titleTextField: NSTextField!
    private var contentTextView: NSTextView!
    private var addButton: NSButton!
    private var removeButton: NSButton!
    private var saveButton: NSButton!
    private var newFolderButton: NSButton!
    private var quickAddButton: NSButton!
    private var templatesButton: NSButton!
    private var searchField: NSSearchField!
    
    private var folders: [CPYFolder] = []
    private var selectedFolder: CPYFolder?
    private var filteredSnippets: [CPYSnippet] = []
    private var isNewSnippet = false
    private var isLoading = false // FIX: Prevent recursive operations
    
    init() {
        print("DEBUG: SnippetEditorWindowController init() started")
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                             styleMask: [.titled, .closable, .resizable],
                             backing: .buffered,
                             defer: false)
        window.title = "Snippet Editor"
        window.center()
        super.init(window: window)
        
        // Setup UI synchronously
        setupUI()
        
        // Load data asynchronously
        loadSnippetsAsync()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // FIX: Make loading asynchronous to prevent blocking
    private func loadSnippetsAsync() {
        guard !isLoading else { return }
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Load folders on background thread
            let loadedFolders = SnippetService.shared.getAllFolders()
            
            var foldersToUse = loadedFolders
            
            // If no folders exist, create sample data
            if foldersToUse.isEmpty {
                self.createSampleSnippets()
                foldersToUse = SnippetService.shared.getAllFolders()
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.folders = foldersToUse
                self.selectedFolder = foldersToUse.first
                
                // Mark loading as complete BEFORE updating UI
                self.isLoading = false
                
                // Update the UI with the loaded data
                self.updateFolderPopup()
                self.updateSnippetList()
                
                // Ensure we have content in the editor if no snippets exist
                if self.selectedFolder?.snippets.isEmpty ?? true {
                    self.clearEditor()
                }
            }
        }
    }
    
    private func createSampleSnippets() {
        // FIX: Simplified sample creation to reduce complexity
        let defaultFolder = SnippetService.shared.createFolder(title: "Common Snippets")
        
        let sampleSnippets = [
            ("Email Signature", "Best regards,\n[Your Name]\n[Your Title]"),
            ("Thank You", "Thank you for your time and consideration."),
            ("Meeting Follow-up", "Hi [Name],\n\nThank you for meeting with me today.")
        ]
        
        for (title, content) in sampleSnippets {
            _ = SnippetService.shared.createSnippet(in: defaultFolder, title: title, content: content)
        }
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // Clear existing content first to prevent conflicts
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Main container with modern layout
        let mainContainer = NSView()
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainContainer)
        
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Setup sections
        setupHeaderSection(in: mainContainer)
        setupMainContentSection(in: mainContainer)
        
        // Load initial data (don't update snippet list or clear editor here, as data will be loaded asynchronously)
        // The loadSnippetsAsync method will handle updating the UI once data is loaded
    }
    
    private func setupHeaderSection(in container: NSView) {
        // Header with title and quick actions
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.addSubview(headerView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Header content
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.distribution = .fillProportionally
        headerStack.spacing = 20
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerStack)
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            headerStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            headerStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            headerStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -20)
        ])
        
        // Title section
        let titleStack = NSStackView()
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 5
        
        let titleLabel = NSTextField(labelWithString: "Snippet Editor") // FIX: Removed emoji
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = NSColor.labelColor
        
        let subtitleLabel = NSTextField(labelWithString: "Create and manage your text snippets")
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = NSColor.secondaryLabelColor
        
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        headerStack.addArrangedSubview(titleStack)
        
        // Quick action buttons
        let actionStack = NSStackView()
        actionStack.orientation = .horizontal
        actionStack.spacing = 10
        
        quickAddButton = NSButton(title: "Quick Add", target: self, action: #selector(quickAddSnippet))
        quickAddButton.styleAsPrimaryButton()
        
        templatesButton = NSButton(title: "Templates", target: self, action: #selector(showTemplates))
        templatesButton.styleAsSecondaryButton()
        
        actionStack.addArrangedSubview(quickAddButton)
        actionStack.addArrangedSubview(templatesButton)
        headerStack.addArrangedSubview(actionStack)
    }
    
    private func setupMainContentSection(in container: NSView) {
        // Main content area below header
        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: container.topAnchor, constant: 80),
            contentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Horizontal layout for left panel and editor
        let mainStack = NSStackView()
        mainStack.orientation = .horizontal
        mainStack.spacing = 1 // Minimal spacing for clean look
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Left panel - Snippet browser
        let leftPanel = NSView()
        leftPanel.translatesAutoresizingMaskIntoConstraints = false
        leftPanel.wantsLayer = true
        leftPanel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        leftPanel.layer?.cornerRadius = 8
        mainStack.addArrangedSubview(leftPanel)
        leftPanel.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        // Right panel - Editor
        let rightPanel = NSView()
        rightPanel.translatesAutoresizingMaskIntoConstraints = false
        rightPanel.wantsLayer = true
        rightPanel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        rightPanel.layer?.cornerRadius = 8
        mainStack.addArrangedSubview(rightPanel)
        
        setupSnippetBrowser(in: leftPanel)
        setupSnippetEditor(in: rightPanel)
    }
    
    private func setupSnippetBrowser(in view: NSView) {
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 15
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        // Folder selection section
        let folderSection = NSStackView()
        folderSection.orientation = .horizontal
        folderSection.spacing = 10
        folderSection.alignment = .centerY
        
        let folderLabel = NSTextField(labelWithString: "Folder:")
        folderLabel.font = NSFont.boldSystemFont(ofSize: 13)
        
        folderPopupButton = NSPopUpButton()
        folderPopupButton.target = self
        folderPopupButton.action = #selector(folderSelectionChanged(_:))
        updateFolderPopup()
        
        newFolderButton = NSButton(title: "+", target: self, action: #selector(createNewFolder))
        newFolderButton.bezelStyle = .circular
        newFolderButton.font = NSFont.boldSystemFont(ofSize: 12)
        
        folderSection.addArrangedSubview(folderLabel)
        folderSection.addArrangedSubview(folderPopupButton)
        folderSection.addArrangedSubview(newFolderButton)
        mainStack.addArrangedSubview(folderSection)
        
        // Search section
        searchField = NSSearchField()
        searchField.placeholderString = "Search snippets..."
        searchField.target = self
        searchField.action = #selector(searchSnippets(_:))
        mainStack.addArrangedSubview(searchField)
        
        // Snippets list
        let listLabel = NSTextField(labelWithString: "Your Snippets")
        listLabel.font = NSFont.boldSystemFont(ofSize: 13)
        mainStack.addArrangedSubview(listLabel)
        
        // Enhanced table view
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.wantsLayer = true
        scrollView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        scrollView.layer?.cornerRadius = 6
        
        snippetTableView = NSTableView()
        snippetTableView.delegate = self
        snippetTableView.dataSource = self
        snippetTableView.allowsMultipleSelection = false
        snippetTableView.rowHeight = 40
        snippetTableView.intercellSpacing = NSSize(width: 0, height: 2)
        snippetTableView.backgroundColor = NSColor.clear
        snippetTableView.headerView = nil
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = "Name"
        nameColumn.width = 250
        snippetTableView.addTableColumn(nameColumn)
        
        scrollView.documentView = snippetTableView
        mainStack.addArrangedSubview(scrollView)
        
        // Action buttons
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        
        addButton = NSButton(title: "New", target: self, action: #selector(addSnippet))
        addButton.styleAsPrimaryButton()
        
        removeButton = NSButton(title: "Delete", target: self, action: #selector(removeSnippet))
        removeButton.styleAsSecondaryButton()
        removeButton.isEnabled = false
        
        buttonStack.addArrangedSubview(addButton)
        buttonStack.addArrangedSubview(removeButton)
        mainStack.addArrangedSubview(buttonStack)
    }
    
    private func setupSnippetEditor(in view: NSView) {
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        // Editor header with status
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 10
        
        let editorTitle = NSTextField(labelWithString: "Edit Snippet")
        editorTitle.font = NSFont.boldSystemFont(ofSize: 16)
        editorTitle.textColor = NSColor.labelColor
        
        headerStack.addArrangedSubview(editorTitle)
        headerStack.addArrangedSubview(NSView()) // Spacer
        mainStack.addArrangedSubview(headerStack)
        
        // Title input section
        let titleSection = NSStackView()
        titleSection.orientation = .vertical
        titleSection.spacing = 8
        
        let titleLabel = NSTextField(labelWithString: "Title")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.textColor = NSColor.labelColor
        
        titleTextField = NSTextField()
        titleTextField.placeholderString = "Enter a descriptive title for your snippet..."
        titleTextField.font = NSFont.systemFont(ofSize: 13)
        titleTextField.target = self
        titleTextField.action = #selector(titleChanged(_:))
        
        titleSection.addArrangedSubview(titleLabel)
        titleSection.addArrangedSubview(titleTextField)
        mainStack.addArrangedSubview(titleSection)
        
        // Content input section
        let contentSection = NSStackView()
        contentSection.orientation = .vertical
        contentSection.spacing = 8
        
        let contentHeaderStack = NSStackView()
        contentHeaderStack.orientation = .horizontal
        contentHeaderStack.alignment = .centerY
        contentHeaderStack.spacing = 10
        
        let contentLabel = NSTextField(labelWithString: "Content")
        contentLabel.font = NSFont.boldSystemFont(ofSize: 13)
        contentLabel.textColor = NSColor.labelColor
        
        let helpLabel = NSTextField(labelWithString: "Tip: Use [placeholders] for dynamic content")
        helpLabel.font = NSFont.systemFont(ofSize: 11)
        helpLabel.textColor = NSColor.secondaryLabelColor
        
        contentHeaderStack.addArrangedSubview(contentLabel)
        contentHeaderStack.addArrangedSubview(NSView()) // Spacer
        contentHeaderStack.addArrangedSubview(helpLabel)
        
        let contentScrollView = NSScrollView()
        contentScrollView.hasVerticalScroller = true
        contentScrollView.borderType = .noBorder
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.wantsLayer = true
        contentScrollView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        contentScrollView.layer?.cornerRadius = 8
        contentScrollView.layer?.borderWidth = 1
        contentScrollView.layer?.borderColor = NSColor.gridColor.cgColor
        
        contentTextView = NSTextView()
        contentTextView.isEditable = true
        contentTextView.isRichText = false
        contentTextView.isSelectable = true // FIX: Ensure text view is selectable
        contentTextView.font = NSFont.userFixedPitchFont(ofSize: 13)
        contentTextView.backgroundColor = NSColor.textBackgroundColor
        contentTextView.insertionPointColor = NSColor.labelColor
        contentTextView.delegate = self
        
        contentScrollView.documentView = contentTextView
        
        contentSection.addArrangedSubview(contentHeaderStack)
        contentSection.addArrangedSubview(contentScrollView)
        mainStack.addArrangedSubview(contentSection)
        
        // Action buttons section
        let actionStack = NSStackView()
        actionStack.orientation = .horizontal
        actionStack.spacing = 10
        actionStack.distribution = .fillEqually
        
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelEditing))
        cancelButton.styleAsSecondaryButton()
        
        saveButton = NSButton(title: "Save Snippet", target: self, action: #selector(saveSnippet))
        saveButton.styleAsPrimaryButton()
        saveButton.isEnabled = false
        
        actionStack.addArrangedSubview(cancelButton)
        actionStack.addArrangedSubview(saveButton)
        mainStack.addArrangedSubview(actionStack)
        
        // Auto-save indicator
        let autoSaveLabel = NSTextField(labelWithString: "Auto-saves as you type")
        autoSaveLabel.font = NSFont.systemFont(ofSize: 10)
        autoSaveLabel.textColor = NSColor.tertiaryLabelColor
    }
    
    // MARK: - Action Methods with Thread Safety
    
    @objc private func quickAddSnippet() {
        // FIX: Check state before proceeding
        guard !isLoading else { return }
        
        if selectedFolder == nil {
            selectedFolder = folders.first ?? createDefaultFolder()
        }
        
        startNewSnippet(withTitle: "New Snippet", content: "Enter your snippet content here...")
    }
    
    @objc private func showTemplates() {
        // FIX: Check state before showing dialog
        guard !isLoading else { return }
        
        let alert = NSAlert()
        alert.messageText = "Choose a Template"
        alert.informativeText = "Select a template to get started quickly:"
        
        alert.addButton(withTitle: "Email Template")
        alert.addButton(withTitle: "Meeting Notes")
        alert.addButton(withTitle: "Code Snippet")
        alert.addButton(withTitle: "Custom")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        var title = ""
        var content = ""
        
        switch response.rawValue {
        case 1000: // Email
            title = "Email Template"
            content = "Subject: [Subject]\n\nHi [Name],\n\n[Your message here]\n\nBest regards,\n[Your Name]"
        case 1001: // Meeting
            title = "Meeting Notes"
            content = "Meeting: [Meeting Title]\nDate: [Date]\nAttendees: [Names]\n\nAgenda:\n• [Topic 1]\n• [Topic 2]\n\nNotes:\n[Meeting notes]\n\nAction Items:\n• [Action 1] - [Owner]\n• [Action 2] - [Owner]"
        case 1002: // Code
            title = "Code Snippet"
            content = "// [Description]\nfunction [functionName]([parameters]) {\n    [code here]\n}"
        case 1003: // Custom
            startNewSnippet(withTitle: "Custom Snippet", content: "")
            return
        default:
            return
        }
        
        startNewSnippet(withTitle: title, content: content)
    }
    
    @objc private func folderSelectionChanged(_ sender: NSPopUpButton) {
        // FIX: Prevent recursion and state conflicts
        guard !isLoading else { return }
        
        let selectedIndex = sender.indexOfSelectedItem
        if selectedIndex >= 0 && selectedIndex < folders.count {
            selectedFolder = folders[selectedIndex]
            updateSnippetListSafely()
        }
    }
    
    @objc private func createNewFolder() {
        guard !isLoading else { return }
        
        let alert = NSAlert()
        alert.messageText = "Create New Folder"
        alert.informativeText = "Enter a name for the new folder:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "Folder name"
        alert.accessoryView = textField
        
        alert.window.initialFirstResponder = textField
        
        if alert.runModal() == .alertFirstButtonReturn {
            let folderName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !folderName.isEmpty {
                // FIX: Perform folder creation on background thread
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }
                    
                    let newFolder = SnippetService.shared.createFolder(title: folderName)
                    let updatedFolders = SnippetService.shared.getAllFolders()
                    
                    DispatchQueue.main.async {
                        self.folders = updatedFolders
                        self.selectedFolder = newFolder
                        self.updateFolderPopup()
                        self.updateSnippetListSafely()
                    }
                }
            }
        }
    }
    
    @objc private func searchSnippets(_ sender: NSSearchField) {
        // FIX: Debounce search to prevent excessive filtering
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        self.perform(#selector(performSearch), with: nil, afterDelay: 0.3)
    }
    
    @objc private func performSearch() {
        let searchTerm = searchField.stringValue.lowercased()
        
        if searchTerm.isEmpty {
            filteredSnippets = selectedFolder?.snippets ?? []
        } else {
            filteredSnippets = (selectedFolder?.snippets ?? []).filter { snippet in
                return snippet.title.lowercased().contains(searchTerm) ||
                       snippet.content.lowercased().contains(searchTerm)
            }
        }
        
        snippetTableView.reloadData()
    }
    
    @objc private func titleChanged(_ sender: NSTextField) {
        enableSaveButtonIfNeeded()
    }
    
    @objc private func cancelEditing() {
        clearEditor()
        isNewSnippet = false
        snippetTableView.deselectAll(nil)
    }
    
    @objc private func addSnippet() {
        startNewSnippet(withTitle: "New Snippet", content: "Enter your content here...")
    }
    
    @objc private func removeSnippet() {
        guard let folder = selectedFolder, !isLoading else { return }
        
        let selectedRowIndexes = snippetTableView.selectedRowIndexes
        guard !selectedRowIndexes.isEmpty else { return }
        
        // Get the actual snippets to remove using the correct folder reference
        let currentSnippets = getCurrentSnippets()
        let snippetsToRemove = selectedRowIndexes.compactMap { index in
            // Use the current snippets (filtered or not) to get the correct indices
            index < currentSnippets.count ? currentSnippets[index] : nil
        }
        
        guard !snippetsToRemove.isEmpty else { return }
        
        // FIX: Perform removal on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            for snippet in snippetsToRemove {
                folder.removeSnippet(snippet)
            }
            
            SnippetService.shared.saveSnippetsToDisk()
            
            DispatchQueue.main.async {
                self.updateSnippetListSafely()
                self.clearEditor()
                self.removeButton.isEnabled = false
                self.saveButton.isEnabled = false
            }
        }
    }
    
    @objc private func saveSnippet() {
        guard let folder = selectedFolder, !isLoading else { return }
        
        let title = titleTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = contentTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !title.isEmpty && !content.isEmpty else { return }
        
        // FIX: Perform save on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if self.isNewSnippet {
                // Creating new snippet
                _ = SnippetService.shared.createSnippet(in: folder, title: title, content: content)
            } else {
                // Updating existing snippet
                let currentSnippets = self.getCurrentSnippets()
                guard let selectedRow = self.snippetTableView.selectedRowIndexes.first,
                      selectedRow < currentSnippets.count else { return }
                
                let snippet = currentSnippets[selectedRow]
                snippet.title = title
                snippet.content = content
                SnippetService.shared.saveSnippetsToDisk()
            }
            
            // Refresh data on main thread
            DispatchQueue.main.async {
                // Update folders and maintain proper folder reference
                self.folders = SnippetService.shared.getAllFolders()
                
                // Find the updated folder reference by title (simpler approach)
                self.selectedFolder = self.folders.first { $0.title == folder.title }
                
                // Ensure we have a selected folder
                if self.selectedFolder == nil && !self.folders.isEmpty {
                    self.selectedFolder = self.folders.first
                }
                
                self.updateSnippetListSafely()
                self.clearEditor()
                self.isNewSnippet = false
                
                // Post notification to update menus
                NotificationCenter.default.post(name: Constants.Notification.clipDataUpdated, object: nil)
            }
        }
    }
    
    // MARK: - Helper Methods with Safety Checks
    
    private func startNewSnippet(withTitle title: String, content: String) {
        guard !isLoading else { return }
        
        titleTextField.stringValue = title
        contentTextView.string = content
        contentTextView.isEditable = true // FIX: Ensure content area is editable when creating new snippet
        isNewSnippet = true
        saveButton.isEnabled = true
        
        // Focus on title field
        window?.makeFirstResponder(titleTextField)
    }
    
    private func createDefaultFolder() -> CPYFolder {
        // FIX: Check if already exists to prevent duplicates
        if let existing = folders.first(where: { $0.title == "My Snippets" }) {
            return existing
        }
        
        let defaultFolder = SnippetService.shared.createFolder(title: "My Snippets")
        folders = SnippetService.shared.getAllFolders()
        updateFolderPopup()
        return defaultFolder
    }
    
    private func updateFolderPopup() {
        folderPopupButton.removeAllItems()
        
        for folder in folders {
            folderPopupButton.addItem(withTitle: folder.title)
        }
        
        if let selected = selectedFolder,
           let index = folders.firstIndex(of: selected) {
            folderPopupButton.selectItem(at: index)
        }
    }
    
    private func enableSaveButtonIfNeeded() {
        let hasTitle = !titleTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasContent = !contentTextView.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        saveButton.isEnabled = hasTitle && hasContent
        
        // FIX: Ensure content area remains editable when there is content
        if hasContent {
            contentTextView.isEditable = true
        }
    }
    
    // FIX: Safe version of updateSnippetList to prevent infinite loops
    private func updateSnippetListSafely() {
        // Use the selected folder if available, otherwise use the first folder
        let snippetsToDisplay: [CPYSnippet]
        if let folder = selectedFolder {
            snippetsToDisplay = folder.snippets
        } else if let firstFolder = folders.first {
            snippetsToDisplay = firstFolder.snippets
        } else {
            snippetsToDisplay = []
        }
        
        filteredSnippets = snippetsToDisplay
        snippetTableView.reloadData()
        
        // Only update folder popup if we're not in the middle of a folder operation
        DispatchQueue.main.async { [weak self] in
            self?.updateFolderPopup()
        }
    }
    
    private func updateSnippetList() {
        updateSnippetListSafely()
    }
    
    private func getCurrentSnippets() -> [CPYSnippet] {
        // Always use the actual folder's snippets unless we're actively searching
        guard let selectedFolder = selectedFolder else { 
            // Fallback to using the folders array if selectedFolder is nil
            if let firstFolder = folders.first {
                return firstFolder.snippets
            }
            return []
        }
        
        // If we have a search term, use filteredSnippets, otherwise use the folder's snippets
        if let searchField = searchField, !searchField.stringValue.isEmpty {
            return filteredSnippets
        } else {
            return selectedFolder.snippets
        }
    }
    
    private func clearEditor() {
        // Don't clear the editor if we're still loading data
        guard !isLoading else { return }
        
        titleTextField.stringValue = ""
        contentTextView.string = getWelcomeMessage()
        contentTextView.isEditable = true // FIX: Ensure content area remains editable
        saveButton.isEnabled = false
        isNewSnippet = false
    }
    
    private func getWelcomeMessage() -> String {
        return """
        Welcome to the Snippet Editor!
        
        Getting Started:
        1. Select a snippet from the list on the left to edit it
        2. Click "Add Snippet" to create a new one
        3. Use placeholders like [Name], [Date], [Topic] in your snippets
        4. Your snippets will be available in the main clipboard menu
        
        Tips:
        • Use descriptive titles for easy identification
        • Create folders to organize different types of snippets
        • Include placeholders that you can quickly replace when pasting
        • Save frequently used text, email templates, code snippets, etc.
        
        Sample snippets have been created to help you get started!
        Select one from the list to see how it works.
        """
    }
    
    private func updateEditor(with snippet: CPYSnippet) {
        titleTextField.stringValue = snippet.title
        contentTextView.string = snippet.content
        contentTextView.isEditable = true // FIX: Ensure content area is editable when updating
        contentTextView.isSelectable = true // FIX: Ensure content area is selectable
        saveButton.isEnabled = true
    }
}

// MARK: - NSTableViewDataSource
extension SnippetEditorWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return getCurrentSnippets().count
    }
}

// MARK: - NSTableViewDelegate
extension SnippetEditorWindowController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let snippets = getCurrentSnippets()
        guard row < snippets.count else { return nil }
        
        let snippet = snippets[row]
        
        // Create modern cell view
        let identifier = NSUserInterfaceItemIdentifier("modernSnippetCell")
        var cellView = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
        
        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = identifier
            
            let containerView = NSView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.wantsLayer = true
            containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            containerView.layer?.cornerRadius = 6
            
            let titleField = NSTextField(labelWithString: "")
            titleField.translatesAutoresizingMaskIntoConstraints = false
            titleField.font = NSFont.boldSystemFont(ofSize: 13)
            titleField.textColor = NSColor.labelColor
            titleField.lineBreakMode = .byTruncatingTail
            
            let previewField = NSTextField(labelWithString: "")
            previewField.translatesAutoresizingMaskIntoConstraints = false
            previewField.font = NSFont.systemFont(ofSize: 11)
            previewField.textColor = NSColor.secondaryLabelColor
            previewField.lineBreakMode = .byTruncatingTail
            
            containerView.addSubview(titleField)
            containerView.addSubview(previewField)
            cellView?.addSubview(containerView)
            
            // Only set up constraints if cellView is not nil
            if let cellView = cellView {
                NSLayoutConstraint.activate([
                    containerView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8),
                    containerView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8),
                    containerView.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 2),
                    containerView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: -2),
                    
                    titleField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                    titleField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                    titleField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
                    
                    previewField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                    previewField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                    previewField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 2),
                    previewField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
                ])
                
                cellView.textField = titleField
                // Store preview field in a more direct way to avoid KVC issues
                cellView.addSubview(previewField)
                previewField.tag = 1001 // Use a tag to identify the preview field
            }
        }
        
        cellView?.textField?.stringValue = snippet.title
        
        // Show content preview using the tagged view
        let preview = snippet.content.prefix(50).replacingOccurrences(of: "\n", with: " ")
        if let cellView = cellView, let previewField = cellView.subviews.first(where: { $0.tag == 1001 }) as? NSTextField {
            previewField.stringValue = String(preview)
        }
        
        return cellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        // FIX: Prevent selection changes during loading
        guard !isLoading else { return }
        
        let snippets = getCurrentSnippets()
        let selectedRowIndexes = snippetTableView.selectedRowIndexes
        
        if selectedRowIndexes.count == 1 {
            if let rowIndex = selectedRowIndexes.first, rowIndex < snippets.count {
                let snippet = snippets[rowIndex]
                updateEditor(with: snippet)
                removeButton.isEnabled = true
                isNewSnippet = false
            } else {
                clearEditor()
                removeButton.isEnabled = false
            }
        } else if selectedRowIndexes.count > 1 {
            // Multiple selection
            clearEditor()
            removeButton.isEnabled = true
        } else {
            // No selection
            clearEditor()
            removeButton.isEnabled = false
        }
    }
}

// MARK: - NSTextViewDelegate
extension SnippetEditorWindowController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        // FIX: Debounce text changes to prevent excessive updates
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayedTextUpdate), object: nil)
        self.perform(#selector(delayedTextUpdate), with: nil, afterDelay: 0.1)
    }
    
    @objc private func delayedTextUpdate() {
        // FIX: Ensure content area remains editable during text changes
        contentTextView.isEditable = true
        contentTextView.isSelectable = true
        enableSaveButtonIfNeeded()
    }
}
import Foundation
import Cocoa

// Simple programmatic preferences window
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
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        stackView.addArrangedSubview(titleLabel)
        
        // History Settings Section
        let historyLabel = NSTextField(labelWithString: "History Settings")
        historyLabel.font = NSFont.boldSystemFont(ofSize: 14)
        stackView.addArrangedSubview(historyLabel)
        
        // Max History Size
        let historySizeView = createLabeledField("Maximum History Size:", width: 180)
        maxHistorySizeField = historySizeView.field
        maxHistorySizeField.target = self
        maxHistorySizeField.action = #selector(maxHistorySizeChanged(_:))
        stackView.addArrangedSubview(historySizeView.container)
        
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
        displayLabel.font = NSFont.boldSystemFont(ofSize: 14)
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
        soundLabel.font = NSFont.boldSystemFont(ofSize: 14)
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
        timingLabel.font = NSFont.boldSystemFont(ofSize: 14)
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
        loginLabel.font = NSFont.boldSystemFont(ofSize: 14)
        stackView.addArrangedSubview(loginLabel)
        
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(launchAtLoginToggled(_:)))
        stackView.addArrangedSubview(launchAtLoginCheckbox)
        
        // Reset Button
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetToDefaults(_:)))
        resetButton.bezelStyle = .rounded
        stackView.addArrangedSubview(resetButton)
    }
    
    private func createLabeledField(_ label: String, width: CGFloat) -> (container: NSView, field: NSTextField) {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        
        let labelField = NSTextField(labelWithString: label)
        labelField.translatesAutoresizingMaskIntoConstraints = false
        
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.stringValue = "20"
        
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
        
        let popupButton = NSPopUpButton()
        popupButton.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        let slider = NSSlider(value: 0.5, minValue: 0.1, maxValue: 2.0, target: nil, action: nil)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = NSTextField(labelWithString: "0.5")
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
            maxHistorySizeField.integerValue = 20
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
        
        // Play preview of selected sound
        ClipService.playSoundEffectPreview(soundType)
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
            UserDefaults.standard.set(20, forKey: Constants.UserDefaults.maxHistorySize)
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

// Simple snippet editor window
class SnippetEditorWindowController: NSWindowController {
    
    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                             styleMask: [.titled, .closable, .resizable],
                             backing: .buffered,
                             defer: false)
        window.title = "Snippet Editor"
        window.center()
        super.init(window: window)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let label = NSTextField(labelWithString: "Snippet Editor - Coming Soon")
        label.font = NSFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
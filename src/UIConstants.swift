import Foundation
import Cocoa

// MARK: - UI Constants and Styling
struct UIConstants {
    
    // MARK: - Color Scheme
    struct Colors {
        // Primary color scheme
        static let primary = NSColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0) // Blue
        static let primaryLight = NSColor(red: 0.54, green: 0.73, blue: 0.95, alpha: 1.0) // Light Blue
        static let primaryDark = NSColor(red: 0.18, green: 0.42, blue: 0.71, alpha: 1.0) // Dark Blue
        
        // Secondary color scheme
        static let secondary = NSColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1.0) // Orange
        static let secondaryLight = NSColor(red: 0.98, green: 0.78, blue: 0.43, alpha: 1.0) // Light Orange
        static let secondaryDark = NSColor(red: 0.80, green: 0.50, blue: 0.05, alpha: 1.0) // Dark Orange
        
        // Neutral colors
        static let background = NSColor.windowBackgroundColor
        static let backgroundSecondary = NSColor.controlBackgroundColor
        static let textPrimary = NSColor.black
        static let textSecondary = NSColor.gray
        static let border = NSColor.lightGray
        static let success = NSColor.green
        static let warning = NSColor.orange
        static let error = NSColor.red
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = NSFont.boldSystemFont(ofSize: 24)
        static let title = NSFont.boldSystemFont(ofSize: 18)
        static let subtitle = NSFont.systemFont(ofSize: 14)
        static let body = NSFont.systemFont(ofSize: 13)
        static let caption = NSFont.systemFont(ofSize: 11)
        static let button = NSFont.systemFont(ofSize: 13)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }
    
    // MARK: - Sizing
    struct Sizing {
        static let buttonHeight: CGFloat = 30
        static let textFieldHeight: CGFloat = 24
        static let iconSize: CGFloat = 20
        static let menuItemHeight: CGFloat = 22
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
    }
}

// MARK: - NSView Extensions for Styling
extension NSView {
    func setCornerRadius(_ radius: CGFloat) {
        self.wantsLayer = true
        self.layer?.cornerRadius = radius
        self.layer?.masksToBounds = true
    }
    
    func setBackgroundColor(_ color: NSColor) {
        self.wantsLayer = true
        self.layer?.backgroundColor = color.cgColor
    }
}

// MARK: - NSButton Extensions for Styling
extension NSButton {
    func styleAsPrimaryButton() {
        self.bezelStyle = .rounded
        self.setButtonType(.momentaryPushIn)
        self.font = UIConstants.Typography.button
        self.wantsLayer = true
        self.layer?.backgroundColor = UIConstants.Colors.primary.cgColor
        self.layer?.cornerRadius = UIConstants.CornerRadius.small
    }
    
    func styleAsSecondaryButton() {
        self.bezelStyle = .rounded
        self.setButtonType(.momentaryPushIn)
        self.font = UIConstants.Typography.button
        self.wantsLayer = true
        self.layer?.borderWidth = 1
        self.layer?.borderColor = UIConstants.Colors.primary.cgColor
        self.layer?.cornerRadius = UIConstants.CornerRadius.small
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    func styleAsDestructiveButton() {
        self.bezelStyle = .rounded
        self.setButtonType(.momentaryPushIn)
        self.font = UIConstants.Typography.button
        self.wantsLayer = true
        self.layer?.backgroundColor = UIConstants.Colors.error.cgColor
        self.layer?.cornerRadius = UIConstants.CornerRadius.small
    }
}

// MARK: - NSTextField Extensions for Styling
extension NSTextField {
    func styleAsTitleLabel() {
        self.font = UIConstants.Typography.title
        self.textColor = UIConstants.Colors.textPrimary
        self.backgroundColor = NSColor.clear
        self.isBordered = false
        self.isEditable = false
        self.isSelectable = false
    }
    
    func styleAsSectionHeader() {
        self.font = UIConstants.Typography.subtitle
        self.textColor = UIConstants.Colors.primary
        self.backgroundColor = NSColor.clear
        self.isBordered = false
        self.isEditable = false
        self.isSelectable = false
    }
    
    func styleAsBodyLabel() {
        self.font = UIConstants.Typography.body
        self.textColor = UIConstants.Colors.textPrimary
        self.backgroundColor = NSColor.clear
        self.isBordered = false
        self.isEditable = false
        self.isSelectable = false
    }
    
    func styleAsCaptionLabel() {
        self.font = UIConstants.Typography.caption
        self.textColor = UIConstants.Colors.textSecondary
        self.backgroundColor = NSColor.clear
        self.isBordered = false
        self.isEditable = false
        self.isSelectable = false
    }
    
    func styleAsTextField() {
        self.font = UIConstants.Typography.body
        self.textColor = UIConstants.Colors.textPrimary
        self.backgroundColor = UIConstants.Colors.backgroundSecondary
        self.isBordered = true
        self.isEditable = true
        self.isSelectable = true
        self.focusRingType = .exterior
        self.wantsLayer = true
        self.layer?.cornerRadius = UIConstants.CornerRadius.small
    }
}
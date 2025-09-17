import Foundation

// Application-wide constants and configuration values
struct Constants {
    
    struct Application {
        static let name = "Clipy"
        static let bundleIdentifier = "com.example.Clipy"
        static let version = "1.0.0"
        static let githubURL = "https://github.com/Clipy/Clipy"
        static let websiteURL = "https://clipy-app.com"
    }
    
    struct Menu {
        static let maxHistorySize = 200
        static let maxMenuItemTitleLength = 15
    }
    
    struct UserDefaults {
        static let loginItem = "loginItem"
        static let maxHistorySize = "maxHistorySize"
        static let menuIconSize = "menuIconSize"
        static let showColorPreviewInMenu = "showColorPreviewInMenu"
        static let reorderClipsAfterPasting = "reorderClipsAfterPasting"
        static let addNumericKeyEquivalents = "addNumericKeyEquivalents"
        static let maxMenuItemTitleLength = "maxMenuItemTitleLength"
        static let numberOfItemsPlaceInline = "numberOfItemsPlaceInline"
        static let numberOfItemsPlaceInsideFolder = "numberOfItemsPlaceInsideFolder"
        static let menuItemsTitleStartWithZero = "menuItemsTitleStartWithZero"
        static let excludedApplicationIdentifiers = "excludedApplicationIdentifiers"
        static let storeTypes = "storeTypes"
        static let showToolTip = "showToolTip"
        static let showImage = "showImage"
        static let showImageInTheMenu = "showImageInTheMenu"
        static let maxImageWidth = "maxImageWidth"
        static let maxImageHeight = "maxImageHeight"
        static let soundEffectEnabled = "soundEffectEnabled"
        static let soundEffectType = "soundEffectType"
        static let timeInterval = "timeInterval"
        static let maxSnippets = "maxSnippets"
        static let numberOfRecentItemsToShow = "numberOfRecentItemsToShow" // New preference
    }
    
    struct Notification {
        static let folderInfoUpdated = NSNotification.Name("FolderInfoUpdated")
        static let clipDataUpdated = NSNotification.Name("ClipDataUpdated")
    }
    
    struct SoundEffect {
        static let pop = "pop"
        static let click = "click"
        static let tick = "tick"
        static let bell = "bell"
        static let chime = "chime"
        static let beep = "beep"
        static let whistle = "whistle"
        static let sms = "sms"
        static let none = "none"
    }
}

// MARK: - Sound Effect Types
enum CPYSoundEffectType: String, CaseIterable {
    case pop = "pop"
    case click = "click"
    case tick = "tick"
    case bell = "bell"
    case chime = "chime"
    case beep = "beep"
    case whistle = "whistle"
    case sms = "sms"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .pop: return "Pop (Default)"
        case .click: return "Click"
        case .tick: return "Tick"
        case .bell: return "Bell"
        case .chime: return "Chime"
        case .beep: return "Beep"
        case .whistle: return "Whistle"
        case .sms: return "SMS"
        case .none: return "Silent"
        }
    }
    
    var systemSoundID: UInt32 {
        switch self {
        case .pop: return 1006      // Pop sound
        case .click: return 1000    // Click sound
        case .tick: return 1016     // Tick sound
        case .bell: return 1005     // Bell sound
        case .chime: return 1008    // Chime sound
        case .beep: return 1004     // Beep sound
        case .whistle: return 1014  // Whistle sound
        case .sms: return 1003      // SMS sound (the one you heard and preferred)
        case .none: return 0        // No sound
        }
    }
    
    var description: String {
        switch self {
        case .pop: return "A pleasant pop sound"
        case .click: return "A crisp click sound"
        case .tick: return "A subtle tick sound"
        case .bell: return "A gentle bell chime"
        case .chime: return "A melodic chime"
        case .beep: return "A simple beep tone"
        case .whistle: return "A short whistle sound"
        case .sms: return "An SMS notification sound"
        case .none: return "No sound effect"
        }
    }
}
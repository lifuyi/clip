import Foundation

// Application-wide constants and configuration values
struct Constants {
    
    struct Application {
        static let name = "Clipy"
        static let bundleIdentifier = "com.clipy.Clipy"
        static let version = "1.0.0"
        static let githubURL = "https://github.com/Clipy/Clipy"
        static let websiteURL = "https://clipy-app.com"
    }
    
    struct Menu {
        static let historyMenuItem = "HistoryMenuItem"
        static let snippetMenuItem = "SnippetMenuItem"
        static let maxHistorySize = 20
        static let maxMenuItemTitleLength = 50
    }
    
    struct Common {
        static let bundlePath = "Contents/Info.plist"
        static let loginItemsEnabledKey = "launchAtLogin"
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
        static let timeInterval = "timeInterval"
    }
    
    struct Beta {
        static let pastePasteboardFirst = "pastePasteboardFirst"
        static let suppressAlertForIdenticalSequentialPastes = "suppressAlertForIdenticalSequentialPastes"
    }
    
    struct Update {
        static let enableAutomaticCheck = "SUEnableAutomaticChecks"
        static let checkInterval = "SUScheduledCheckInterval"
    }
    
    struct Notification {
        static let changeDisplayModePreview = NSNotification.Name("ChangeDisplayModePreview")
        static let changeStoreTypesPreview = NSNotification.Name("ChangeStoreTypesPreview")
        static let changeMenuIconPreview = NSNotification.Name("ChangeMenuIconPreview")
        static let changeFolderNamesPreview = NSNotification.Name("ChangeFolderNamesPreview")
        static let folderInfoUpdated = NSNotification.Name("FolderInfoUpdated")
        static let clipDataUpdated = NSNotification.Name("ClipDataUpdated")
    }
    
    struct Xml {
        static let kXMLStringEncoding = "UTF-8"
        static let kXMLFileExtension = "cpyxml"
        static let kRootElement = "clips"
        static let kSnippetsElement = "snippets"
        static let kSnippetElement = "snippet"
        static let kFoldersElement = "folders"
        static let kFolderElement = "folder"
    }
    
    struct HotKey {
        static let mainKeyCombo = "MainKeyCombo"
        static let historyKeyCombo = "HistoryKeyCombo"
        static let snippetKeyCombo = "SnippetKeyCombo"
    }
}
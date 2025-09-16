import Foundation

// Menu type enumeration for different menu contexts
enum MenuType: String, CaseIterable {
    case main = "main"
    case history = "history" 
    case snippet = "snippet"
    
    var userDefaultsKey: String {
        switch self {
        case .main:
            return Constants.HotKey.mainKeyCombo
        case .history:
            return Constants.HotKey.historyKeyCombo
        case .snippet:
            return Constants.HotKey.snippetKeyCombo
        }
    }
    
    var hotKeySelector: Selector {
        switch self {
        case .main:
            return #selector(AppDelegate.popUpMainMenu)
        case .history:
            return #selector(AppDelegate.popUpHistoryMenu)
        case .snippet:
            return #selector(AppDelegate.popUpSnippetMenu)
        }
    }
    
    var title: String {
        switch self {
        case .main:
            return "Main Menu"
        case .history:
            return "History Menu"
        case .snippet:
            return "Snippet Menu"
        }
    }
}
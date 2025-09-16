import Foundation
import Cocoa

// MARK: - CPYAppInfo
class CPYAppInfo: NSObject, NSCoding {
    let bundleIdentifier: String
    let appName: String
    let executableName: String
    let localizedName: String
    
    init?(info: [AnyHashable: Any]) {
        guard let bundleIdentifier = info[kCFBundleIdentifierKey] as? String,
              let appName = info[kCFBundleNameKey] as? String,
              let executableName = info[kCFBundleExecutableKey] as? String else {
            return nil
        }
        
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.executableName = executableName
        self.localizedName = info["CFBundleDisplayName"] as? String ?? appName
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        guard let bundleIdentifier = coder.decodeObject(forKey: "bundleIdentifier") as? String,
              let appName = coder.decodeObject(forKey: "appName") as? String,
              let executableName = coder.decodeObject(forKey: "executableName") as? String,
              let localizedName = coder.decodeObject(forKey: "localizedName") as? String else {
            return nil
        }
        
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.executableName = executableName
        self.localizedName = localizedName
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(bundleIdentifier, forKey: "bundleIdentifier")
        coder.encode(appName, forKey: "appName")
        coder.encode(executableName, forKey: "executableName")
        coder.encode(localizedName, forKey: "localizedName")
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CPYAppInfo else { return false }
        return bundleIdentifier == other.bundleIdentifier
    }
    
    override var hash: Int {
        return bundleIdentifier.hashValue
    }
}

// MARK: - CPYClipData
class CPYClipData: NSObject, NSCoding, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    let types: [String]
    let fileNames: [String]?
    let URLs: [URL]?
    let stringValue: String?
    let RTFData: Data?
    let PDF: Data?
    let image: NSImage?
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(stringValue)
        hasher.combine(RTFData)
        hasher.combine(PDF)
        hasher.combine(fileNames)
        hasher.combine(URLs?.map { $0.absoluteString })
        return hasher.finalize()
    }
    
    var primaryType: NSPasteboard.PasteboardType {
        if stringValue != nil {
            return .string
        } else if RTFData != nil {
            return .rtf
        } else if image != nil {
            return .tiff
        } else if PDF != nil {
            return .pdf
        } else if fileNames != nil {
            return .fileURL
        }
        return .string
    }
    
    var isOnlyStringType: Bool {
        return types.count == 1 && types.first == NSPasteboard.PasteboardType.string.rawValue
    }
    
    var thumbnailImage: NSImage? {
        return image?.resizeImage(128, 128)
    }
    
    var colorCodeImage: NSImage? {
        guard let string = stringValue,
              let color = NSColor(string: string) else { return nil }
        return NSImage.create(with: color, size: NSSize(width: 16, height: 16))
    }
    
    init(pasteboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) {
        // Store raw string values instead of NSPasteboard.PasteboardType
        self.types = types.map { $0.rawValue }
        
        // Extract string value with safety check
        self.stringValue = {
            do {
                return pasteboard.string(forType: .string)
            } catch {
                print("Error reading string from pasteboard: \(error)")
                return nil
            }
        }()
        
        // Extract RTF data with safety check
        self.RTFData = {
            do {
                return pasteboard.data(forType: .rtf)
            } catch {
                print("Error reading RTF from pasteboard: \(error)")
                return nil
            }
        }()
        
        // Extract PDF data with safety check
        self.PDF = {
            do {
                return pasteboard.data(forType: .pdf)
            } catch {
                print("Error reading PDF from pasteboard: \(error)")
                return nil
            }
        }()
        
        // Extract image with safety check and memory management
        self.image = {
            do {
                guard let imageData = pasteboard.data(forType: .tiff) else { return nil }
                
                // Limit image size to prevent memory issues
                if imageData.count > 50 * 1024 * 1024 { // 50MB limit
                    print("Image too large, skipping: \(imageData.count) bytes")
                    return nil
                }
                
                return NSImage(data: imageData)
            } catch {
                print("Error reading image from pasteboard: \(error)")
                return nil
            }
        }()
        
        // Extract file URLs with safety check
        (self.URLs, self.fileNames) = {
            do {
                if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
                    return (urls, urls.map { $0.lastPathComponent })
                } else {
                    return (nil, nil)
                }
            } catch {
                print("Error reading URLs from pasteboard: \(error)")
                return (nil, nil)
            }
        }()
        
        super.init()
    }
    
    init(image: NSImage) {
        self.types = [NSPasteboard.PasteboardType.tiff.rawValue]
        self.image = image
        self.stringValue = nil
        self.RTFData = nil
        self.PDF = nil
        self.fileNames = nil
        self.URLs = nil
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        // Decode types as [String] instead of [NSPasteboard.PasteboardType]
        guard let types = coder.decodeObject(forKey: "types") as? [String] else {
            return nil
        }
        self.types = types
        
        self.stringValue = coder.decodeObject(forKey: "stringValue") as? String
        self.RTFData = coder.decodeObject(forKey: "RTFData") as? Data
        self.PDF = coder.decodeObject(forKey: "PDF") as? Data
        self.image = coder.decodeObject(forKey: "image") as? NSImage
        self.fileNames = coder.decodeObject(forKey: "fileNames") as? [String]
        self.URLs = coder.decodeObject(forKey: "URLs") as? [URL]
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        // Encode types as [String] instead of [NSPasteboard.PasteboardType]
        coder.encode(types, forKey: "types")
        coder.encode(stringValue, forKey: "stringValue")
        coder.encode(RTFData, forKey: "RTFData")
        coder.encode(PDF, forKey: "PDF")
        coder.encode(image, forKey: "image")
        coder.encode(fileNames, forKey: "fileNames")
        coder.encode(URLs, forKey: "URLs")
    }
    
    static var availableTypes: [NSPasteboard.PasteboardType] {
        return [.string, .rtf, .pdf, .tiff, .fileURL]
    }
    
    static var availableTypesString: [String] {
        return availableTypes.map { $0.rawValue }
    }
    
    static var availableTypesDictionary: [String: NSNumber] {
        var dict: [String: NSNumber] = [:]
        for (index, type) in availableTypes.enumerated() {
            dict[type.rawValue] = NSNumber(value: index)
        }
        return dict
    }
}

// MARK: - CPYClip
class CPYClip: NSObject {
    let identifier: String
    let dataPath: String
    var title: String
    let dataHash: Int
    let primaryType: NSPasteboard.PasteboardType
    let updateTime: Date
    let thumbnailPath: String?
    let isColorCode: Bool
    
    var clipData: CPYClipData? {
        guard let data = NSData(contentsOfFile: dataPath) else {
            return nil
        }
        
        do {
            if #available(macOS 10.13, *) {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: CPYClipData.self, from: data as Data)
            } else {
                return NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? CPYClipData
            }
        } catch {
            print("Error unarchiving clip data: \(error)")
            return nil
        }
    }
    
    init(identifier: String, clipData: CPYClipData) {
        self.identifier = identifier
        self.dataHash = clipData.hash
        self.primaryType = clipData.primaryType
        self.updateTime = Date()
        self.isColorCode = clipData.colorCodeImage != nil
        
        // Generate title with maximum 20 characters from the first line only
        if let string = clipData.stringValue {
            // Get the first line only
            let lines = string.components(separatedBy: .newlines)
            let firstLine = lines.first ?? ""
            
            // Limit the first line to 20 characters
            if firstLine.count > 20 {
                self.title = String(firstLine.prefix(20)) + "..."
            } else {
                self.title = firstLine
            }
        } else if clipData.image != nil {
            self.title = "Image"
        } else if let fileNames = clipData.fileNames {
            // For file names, also show only first name and limit to 20 characters
            let firstName = fileNames.first ?? "File"
            if firstName.count > 20 {
                self.title = String(firstName.prefix(20)) + "..."
            } else {
                self.title = firstName
            }
        } else {
            self.title = "Clipboard Item"
        }
        
        // Save data to file
        let appSupportPath = CPYUtilities.applicationSupportFolder()
        self.dataPath = "\(appSupportPath)/\(identifier).data"
        
        // Save thumbnail if image
        if let image = clipData.thumbnailImage {
            let thumbnailPath = "\(appSupportPath)/\(identifier)_thumb.tiff"
            if let tiffData = image.tiffRepresentation {
                try? tiffData.write(to: URL(fileURLWithPath: thumbnailPath))
                self.thumbnailPath = thumbnailPath
            } else {
                self.thumbnailPath = nil
            }
        } else {
            self.thumbnailPath = nil
        }
        
        super.init()
        
        // Save clip data with proper error handling
        do {
            let archivedData: Data
            if #available(macOS 10.13, *) {
                archivedData = try NSKeyedArchiver.archivedData(withRootObject: clipData, requiringSecureCoding: false)
            } else {
                archivedData = NSKeyedArchiver.archivedData(withRootObject: clipData)
            }
            try archivedData.write(to: URL(fileURLWithPath: dataPath))
        } catch {
            print("Error saving clip data: \(error)")
        }
    }
}

// MARK: - CPYSnippet
class CPYSnippet: NSObject {
    let identifier: String
    var title: String
    var content: String
    var enable: Bool
    var index: Int
    
    init(title: String, content: String) {
        self.identifier = UUID().uuidString
        self.title = title
        self.content = content
        self.enable = true
        self.index = 0
        super.init()
    }
}

// MARK: - CPYFolder
class CPYFolder: NSObject {
    let identifier: String
    var title: String
    var enable: Bool
    var index: Int
    var snippets: [CPYSnippet]
    
    init(title: String) {
        self.identifier = UUID().uuidString
        self.title = title
        self.enable = true
        self.index = 0
        self.snippets = []
        super.init()
    }
    
    func createSnippet() -> CPYSnippet {
        let snippet = CPYSnippet(title: "New Snippet", content: "")
        snippet.index = snippets.count
        return snippet
    }
    
    func addSnippet(_ snippet: CPYSnippet) {
        snippets.append(snippet)
        rearrangeSnippetIndices()
    }
    
    func removeSnippet(_ snippet: CPYSnippet) {
        snippets.removeObject(snippet)
        rearrangeSnippetIndices()
    }
    
    private func rearrangeSnippetIndices() {
        for (index, snippet) in snippets.enumerated() {
            snippet.index = index
        }
    }
}

// MARK: - Utilities
class CPYUtilities {
    static func applicationSupportFolder() -> String {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls.first!.appendingPathComponent(Constants.Application.name)
        
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appSupportURL.path
    }
    
    static func registerUserDefaultKeys() {
        let defaults: [String: Any] = [
            Constants.UserDefaults.maxHistorySize: 20,
            Constants.UserDefaults.menuIconSize: 18,
            Constants.UserDefaults.showColorPreviewInMenu: true,
            Constants.UserDefaults.reorderClipsAfterPasting: true,
            Constants.UserDefaults.addNumericKeyEquivalents: true,
            Constants.UserDefaults.maxMenuItemTitleLength: 50,
            Constants.UserDefaults.numberOfItemsPlaceInline: 10,
            Constants.UserDefaults.numberOfItemsPlaceInsideFolder: 10,
            Constants.UserDefaults.menuItemsTitleStartWithZero: false,
            Constants.UserDefaults.showToolTip: true,
            Constants.UserDefaults.showImage: true,
            Constants.UserDefaults.showImageInTheMenu: true,
            Constants.UserDefaults.maxImageWidth: 200,
            Constants.UserDefaults.maxImageHeight: 200,
            Constants.UserDefaults.soundEffectEnabled: true,
            Constants.UserDefaults.soundEffectType: Constants.SoundEffect.sms,  // Changed to SMS sound
            Constants.UserDefaults.timeInterval: 0.5,
            Constants.UserDefaults.storeTypes: CPYClipData.availableTypesDictionary
        ]
        
        UserDefaults.standard.register(defaults: defaults)
        
        // Also set these values explicitly to ensure they exist
        if UserDefaults.standard.object(forKey: Constants.UserDefaults.soundEffectEnabled) == nil {
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.soundEffectEnabled)
        }
        
        if UserDefaults.standard.object(forKey: Constants.UserDefaults.soundEffectType) == nil {
            UserDefaults.standard.set(Constants.SoundEffect.sms, forKey: Constants.UserDefaults.soundEffectType)
        }
    }
}

// MARK: - NSColor String Extension
extension NSColor {
    convenience init?(string: String) {
        let hexString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for hex color format
        if hexString.hasPrefix("#") && hexString.count == 7 {
            let hex = String(hexString.dropFirst())
            if let rgbValue = UInt32(hex, radix: 16) {
                let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
                let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
                let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
                self.init(red: red, green: green, blue: blue, alpha: 1.0)
                return
            }
        }
        
        return nil
    }
}
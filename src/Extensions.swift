import Foundation
import Cocoa

// MARK: - Array Extensions
extension Array where Element: Equatable {
    mutating func removeObject(_ object: Element) {
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }
    
    mutating func removeObjects(_ objects: [Element]) {
        for object in objects {
            removeObject(object)
        }
    }
}

// MARK: - Collection Safe Access
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Bundle Version
extension Bundle {
    var appVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

// MARK: - NSCoding Archive Utilities
extension NSCoding {
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
}

extension Array where Element: NSCoding {
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
}

// MARK: - NSImage Utilities
extension NSImage {
    static func create(with color: NSColor, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }
    
    func resizeImage(_ width: CGFloat, _ height: CGFloat) -> NSImage? {
        let newSize = NSSize(width: width, height: height)
        let newImage = NSImage(size: newSize)
        
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
    }
}

// MARK: - NSMenuItem Convenience
extension NSMenuItem {
    convenience init(title: String, action: Selector?) {
        self.init(title: title, action: action, keyEquivalent: "")
    }
}

// MARK: - UserDefaults Archive Data
extension UserDefaults {
    func setArchiveData<T: NSCoding>(_ object: T, forKey key: String) {
        let data = object.archive()
        set(data, forKey: key)
    }
    
    func archiveDataForKey<T: NSCoding>(_ type: T.Type, key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
    }
}

// MARK: - String Substring
extension String {
    subscript(range: Range<Int>) -> String {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
}

// MARK: - NSLock Convenience
extension NSLock {
    convenience init(name: String) {
        self.init()
        self.name = name
    }
}
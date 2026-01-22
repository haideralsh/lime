import SwiftUI
import AppKit
import CoreText

enum Typography {
    static let fontName = "Google Sans Code"
    
    static func registerFonts() {
        guard let resourceURL = Bundle.main.resourceURL else { return }
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: nil
        ) else { return }
        
        while let fileURL = enumerator.nextObject() as? URL {
            if fileURL.pathExtension.lowercased() == "ttf" &&
               fileURL.lastPathComponent.contains("GoogleSansCode") {
                CTFontManagerRegisterFontsForURL(fileURL as CFURL, .process, nil)
            }
        }
    }
    
    static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(fontName, size: size).weight(weight)
    }
    
    static func nsFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        if let font = NSFont(name: fontName, size: size) {
            return font
        }
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }
}

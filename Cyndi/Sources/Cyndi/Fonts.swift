import SwiftUI
import CoreText
import AppKit

enum Fonts {
    private(set) static var caveatFamily = "Caveat"
    private(set) static var kalamFamily = "Kalam"

    private static func fontURL(_ name: String) -> URL? {
        let main = Bundle.main
        if let direct = main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") {
            return direct
        }
        let candidates = [
            main.resourceURL?.appendingPathComponent("Cyndi_Cyndi.bundle"),
            main.bundleURL.appendingPathComponent("Cyndi_Cyndi.bundle"),
        ].compactMap { $0 }
        for path in candidates {
            if let bundle = Bundle(url: path),
               let url = bundle.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") {
                return url
            }
        }
        return nil
    }

    static func register() {
        for name in ["Caveat", "Kalam-Regular"] {
            guard let url = fontURL(name) else {
                continue
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
               let first = descs.first,
               let family = CTFontDescriptorCopyAttribute(first, kCTFontFamilyNameAttribute) as? String {
                if name.hasPrefix("Caveat") { caveatFamily = family }
                if name.hasPrefix("Kalam") { kalamFamily = family }
            }
        }
    }

    static func caveat(_ size: CGFloat) -> Font {
        .custom(caveatFamily, fixedSize: size).weight(.semibold)
    }

    static func kalam(_ size: CGFloat) -> Font {
        .custom(kalamFamily, fixedSize: size)
    }

    static func kalamNS(_ size: CGFloat) -> NSFont {
        nsFont(family: kalamFamily, size: size)
    }

    private static func nsFont(family: String, size: CGFloat) -> NSFont {
        let descriptor = NSFontDescriptor(fontAttributes: [.family: family])
        return NSFont(descriptor: descriptor, size: size) ?? .systemFont(ofSize: size)
    }
}

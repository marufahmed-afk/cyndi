import SwiftUI
import CoreText

enum Fonts {
    private(set) static var caveatFamily = "Caveat"
    private(set) static var kalamFamily = "Kalam"

    static func register() {
        for name in ["Caveat", "Kalam-Regular"] {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else {
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
}

import SwiftUI
import CoreText

public enum AppFont {
    public static let jakartaLight = "PlusJakartaSans-Light"
    public static let jakartaRegular = "PlusJakartaSans-Regular"
    public static let jakartaMedium = "PlusJakartaSans-Medium"
    public static let jakartaSemiBold = "PlusJakartaSans-SemiBold"
    public static let jakartaBold = "PlusJakartaSans-Bold"

    public static let jetbrainsRegular = "JetBrainsMono-Regular"
    public static let jetbrainsMedium = "JetBrainsMono-Medium"
    public static let jetbrainsSemiBold = "JetBrainsMono-SemiBold"
    public static let jetbrainsBold = "JetBrainsMono-Bold"

    public static func register() {
        let names: [String] = [
            jakartaLight, jakartaRegular, jakartaMedium, jakartaSemiBold, jakartaBold,
            jetbrainsRegular, jetbrainsMedium, jetbrainsSemiBold, jetbrainsBold,
        ]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf")
                      ?? Bundle.module.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Font not found: \(name)")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    public static func jakarta(size: CGFloat, weight: Font.Weight) -> Font {
        let name: String
        switch weight {
        case .light: name = jakartaLight
        case .regular: name = jakartaRegular
        case .medium: name = jakartaMedium
        case .semibold: name = jakartaSemiBold
        case .bold: name = jakartaBold
        default: name = jakartaRegular
        }
        return .custom(name, size: size)
    }

    public static func jetbrains(size: CGFloat, weight: Font.Weight) -> Font {
        let name: String
        switch weight {
        case .medium: name = jetbrainsMedium
        case .semibold: name = jetbrainsSemiBold
        case .bold: name = jetbrainsBold
        default: name = jetbrainsRegular
        }
        return .custom(name, size: size)
    }
}

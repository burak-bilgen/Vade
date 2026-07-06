import SwiftUI
import UIKit

/// Typography definitions using Inter (UI text) and JetBrains Mono (amounts/numbers).
/// Inter is the gold standard for modern fintech UI — clean, warm, highly legible.
/// JetBrains Mono provides tabular figures for precise amount alignment.
/// System font is used as fallback for any glyphs not present in custom fonts
/// (ensures proper rendering of Turkish characters: ı, İ, ş, ğ, ü, ö, ç).
public enum Typography {
    public enum FontRole {
        case display, title1, title2, headline, body, amount, caption, label, hero, onboardingIcon
    }

    private static func customFont(named name: String, size: CGFloat, textStyle: UIFont.TextStyle) -> Font {
        let descriptor = UIFontDescriptor(name: name, size: size)
            .addingAttributes([
                .cascadeList: [
                    // System font fallback for Turkish chars and any missing glyphs
                    UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle),
                ]
            ])
        let uiFont = UIFont(descriptor: descriptor, size: size)
        return Font(uiFont)
    }

    /// Returns the custom font for the given role with Dynamic Type support and Turkish glyph fallback.
    public static func font(for role: FontRole) -> Font {
        switch role {
        case .display:
            customFont(named: "JetBrainsMono-Medium", size: 34, textStyle: .largeTitle)
        case .title1:
            customFont(named: "Inter-SemiBold", size: 28, textStyle: .title1)
        case .title2:
            customFont(named: "Inter-SemiBold", size: 20, textStyle: .title2)
        case .headline:
            customFont(named: "Inter-Medium", size: 17, textStyle: .headline)
        case .body:
            customFont(named: "Inter-Regular", size: 16, textStyle: .body)
        case .amount:
            customFont(named: "JetBrainsMono-Medium", size: 16, textStyle: .body)
        case .caption:
            customFont(named: "Inter-Regular", size: 13, textStyle: .caption1)
        case .label:
            customFont(named: "Inter-Medium", size: 11, textStyle: .caption2)
        case .hero:
            customFont(named: "Inter-Bold", size: 56, textStyle: .largeTitle)
        case .onboardingIcon:
            customFont(named: "Inter-SemiBold", size: 52, textStyle: .largeTitle)
        }
    }
}

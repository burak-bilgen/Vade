import SwiftUI

/// Typography definitions using Inter (UI text) and JetBrains Mono (amounts/numbers).
/// Inter is the gold standard for modern fintech UI — clean, warm, highly legible.
/// JetBrains Mono provides tabular figures for precise amount alignment.
public enum Typography {
    public enum FontRole {
        case display, title1, title2, headline, body, amount, caption, hero, onboardingIcon
    }

    public static func font(for role: FontRole) -> Font {
        switch role {
        case .display:
            Font.custom("JetBrainsMono-Medium", size: 34, relativeTo: .largeTitle)
        case .title1:
            Font.custom("Inter-SemiBold", size: 28, relativeTo: .title)
        case .title2:
            Font.custom("Inter-SemiBold", size: 20, relativeTo: .title2)
        case .headline:
            Font.custom("Inter-Medium", size: 17, relativeTo: .headline)
        case .body:
            Font.custom("Inter-Regular", size: 16, relativeTo: .body)
        case .amount:
            Font.custom("JetBrainsMono-Medium", size: 16, relativeTo: .body)
        case .caption:
            Font.custom("Inter-Regular", size: 13, relativeTo: .caption)
        case .hero:
            Font.custom("Inter-Bold", size: 56, relativeTo: .largeTitle)
        case .onboardingIcon:
            Font.custom("Inter-SemiBold", size: 52, relativeTo: .largeTitle)
        }
    }
}

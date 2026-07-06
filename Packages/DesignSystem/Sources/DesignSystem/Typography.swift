import SwiftUI

/// Typography definitions using Plus Jakarta Sans and JetBrains Mono.
public enum Typography {
    public enum FontRole {
        case display, title1, title2, headline, body, amount, caption
    }

    public static func font(for role: FontRole) -> Font {
        switch role {
        case .display:
            Font.custom("JetBrainsMono-Medium", size: 34, relativeTo: .largeTitle)
        case .title1:
            Font.custom("PlusJakartaSans-SemiBold", size: 28, relativeTo: .title)
        case .title2:
            Font.custom("PlusJakartaSans-SemiBold", size: 20, relativeTo: .title2)
        case .headline:
            Font.custom("PlusJakartaSans-Medium", size: 17, relativeTo: .headline)
        case .body:
            Font.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body)
        case .amount:
            Font.custom("JetBrainsMono-Medium", size: 16, relativeTo: .body)
        case .caption:
            Font.custom("PlusJakartaSans-Regular", size: 13, relativeTo: .caption)
        }
    }
}

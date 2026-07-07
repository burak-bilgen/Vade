import SwiftUI

public enum Typography {
    public enum FontRole: Sendable {
        case display
        case displayMedium
        case title
        case titleItalic
        case title2
        case headline
        case body
        case bodyItalic
        case bodyEmphasis
        case bodyEmphasisItalic
        case amount
        case amountSmall
        case caption
        case captionItalic
        case label
        case labelEmphasis
        case button
        case buttonSmall
        case tab
    }

    public static func font(for role: FontRole) -> Font {
        switch role {
        case .display:
            AppFont.jakarta(size: 40, weight: .semibold).monospacedDigit()
        case .displayMedium:
            AppFont.jakarta(size: 32, weight: .medium).monospacedDigit()
        case .title:
            AppFont.jakarta(size: 24, weight: .bold)
        case .titleItalic:
            AppFont.jakartaItalic(size: 24, weight: .bold)
        case .title2:
            AppFont.jakarta(size: 18, weight: .bold)
        case .headline:
            AppFont.jakarta(size: 16, weight: .bold)
        case .body:
            AppFont.jakarta(size: 15, weight: .medium)
        case .bodyItalic:
            AppFont.jakartaItalic(size: 15, weight: .medium)
        case .bodyEmphasis:
            AppFont.jakarta(size: 15, weight: .semibold)
        case .bodyEmphasisItalic:
            AppFont.jakartaItalic(size: 15, weight: .semibold)
        case .amount:
            AppFont.jetbrains(size: 16, weight: .semibold).monospacedDigit()
        case .amountSmall:
            AppFont.jetbrains(size: 14, weight: .medium).monospacedDigit()
        case .caption:
            AppFont.jakarta(size: 13, weight: .medium)
        case .captionItalic:
            AppFont.jakartaItalic(size: 13, weight: .medium)
        case .label:
            AppFont.jakarta(size: 11, weight: .bold)
        case .labelEmphasis:
            AppFont.jakarta(size: 11, weight: .heavy)
        case .button:
            AppFont.jakarta(size: 16, weight: .bold)
        case .buttonSmall:
            AppFont.jakarta(size: 13, weight: .semibold)
        case .tab:
            AppFont.jakarta(size: 10, weight: .semibold)
        }
    }

    public static func tracking(for role: FontRole) -> CGFloat {
        switch role {
        case .display: return -0.6
        case .displayMedium: return -0.4
        case .title, .titleItalic: return -0.3
        case .title2: return -0.2
        case .label, .labelEmphasis: return 0.3
        case .button: return 0.2
        case .tab: return 0.5
        default: return 0
        }
    }
}

public extension Font {
    static let amount = Typography.font(for: .amount)
    static let display = Typography.font(for: .display)
}

import SwiftUI

// MARK: - Premium Typography System

/// Vade uses PlusJakartaSans for all UI text and JetBrains Mono for monetary amounts.
/// Call `AppFont.register()` at app startup to load the bundled fonts.
public enum Typography {
    public enum FontRole: Sendable {
        case display          // Hero display — 40pt Light Jakarta
        case displayMedium    // Large display — 32pt Light Jakarta (cards)
        case title            // Screen titles — 24pt Bold Jakarta
        case title2           // Section headers — 18pt SemiBold Jakarta
        case headline         // Row / card titles — 16pt SemiBold Jakarta
        case body             // Body text — 15pt Regular Jakarta
        case bodyEmphasis     // Body + emphasis — 15pt Medium Jakarta
        case amount           // Monetary amounts — 16pt Medium JetBrains Mono
        case amountSmall      // Small amounts — 14pt Medium JetBrains Mono
        case caption          // Caption / secondary — 13pt Regular Jakarta
        case label            // Tiny labels — 11pt Medium Jakarta
        case button           // Button text — 16pt SemiBold Jakarta
        case buttonSmall      // Small button / chip — 13pt SemiBold Jakarta
        case tab              // Tab bar — 10pt Medium Jakarta
    }

    public static func font(for role: FontRole) -> Font {
        switch role {
        case .display:
            AppFont.jakarta(size: 40, weight: .light).monospacedDigit()
        case .displayMedium:
            AppFont.jakarta(size: 32, weight: .light).monospacedDigit()
        case .title:
            AppFont.jakarta(size: 24, weight: .bold)
        case .title2:
            AppFont.jakarta(size: 18, weight: .semibold)
        case .headline:
            AppFont.jakarta(size: 16, weight: .semibold)
        case .body:
            AppFont.jakarta(size: 15, weight: .regular)
        case .bodyEmphasis:
            AppFont.jakarta(size: 15, weight: .medium)
        case .amount:
            AppFont.jetbrains(size: 16, weight: .medium).monospacedDigit()
        case .amountSmall:
            AppFont.jetbrains(size: 14, weight: .medium).monospacedDigit()
        case .caption:
            AppFont.jakarta(size: 13, weight: .regular)
        case .label:
            AppFont.jakarta(size: 11, weight: .medium)
        case .button:
            AppFont.jakarta(size: 16, weight: .semibold)
        case .buttonSmall:
            AppFont.jakarta(size: 13, weight: .semibold)
        case .tab:
            AppFont.jakarta(size: 10, weight: .medium)
        }
    }

    /// Tracking (letter-spacing) values for each role.
    /// Apply via `.tracking(Typography.tracking(for: .title))` on Text.
    public static func tracking(for role: FontRole) -> CGFloat {
        switch role {
        case .display: return -0.8
        case .displayMedium: return -0.5
        case .title: return -0.3
        case .title2: return -0.2
        case .label: return 0.3
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

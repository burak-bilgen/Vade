import SwiftUI

// MARK: - Minimalist Typography System

/// Vade uses SF Pro Rounded for all UI text and SF Mono for monetary amounts.
/// No custom fonts needed — fully native, lightweight, and consistent with the iOS ecosystem.
///
/// ## Usage
/// ```swift
/// Text("₺1.500,00")
///     .font(Typography.font(for: .amount))
/// ```
public enum Typography {
    /// Semantic role for each text style.
    public enum FontRole: Sendable {
        /// Hero display amount — 40pt Light Rounded
        case display
        /// Large display amount — 32pt Light Rounded (for cards)
        case displayMedium
        /// Screen titles — 24pt Bold Rounded
        case title
        /// Section headers — 18pt SemiBold Rounded
        case title2
        /// Row / card titles — 16pt SemiBold Rounded
        case headline
        /// Body text — 15pt Regular Rounded
        case body
        /// Body text with emphasis — 15pt Medium Rounded
        case bodyEmphasis
        /// Monetary amounts — 16pt Medium Monospaced
        case amount
        /// Small amounts / secondary values — 14pt Medium Monospaced
        case amountSmall
        /// Caption / secondary text — 13pt Regular Rounded
        case caption
        /// Tiny labels — 11pt Medium Rounded
        case label
        /// Button text — 16pt SemiBold Rounded
        case button
        /// Small button / chip text — 13pt SemiBold Rounded
        case buttonSmall
        /// Tab bar item — 10pt Medium Rounded
        case tab
    }

    /// Returns a SwiftUI `Font` for the given semantic role.
    /// - Uses `.system(..., design: .rounded)` for UI text.
    /// - Uses `.system(..., design: .monospaced)` for monetary amounts.
    public static func font(for role: FontRole) -> Font {
        switch role {
        case .display:
            .system(size: 40, weight: .light, design: .rounded).monospacedDigit()
        case .displayMedium:
            .system(size: 32, weight: .light, design: .rounded).monospacedDigit()
        case .title:
            .system(size: 24, weight: .bold, design: .rounded)
        case .title2:
            .system(size: 18, weight: .semibold, design: .rounded)
        case .headline:
            .system(size: 16, weight: .semibold, design: .rounded)
        case .body:
            .system(size: 15, weight: .regular, design: .rounded)
        case .bodyEmphasis:
            .system(size: 15, weight: .medium, design: .rounded)
        case .amount:
            .system(size: 16, weight: .medium, design: .monospaced).monospacedDigit()
        case .amountSmall:
            .system(size: 14, weight: .medium, design: .monospaced).monospacedDigit()
        case .caption:
            .system(size: 13, weight: .regular, design: .rounded)
        case .label:
            .system(size: 11, weight: .medium, design: .rounded)
        case .button:
            .system(size: 16, weight: .semibold, design: .rounded)
        case .buttonSmall:
            .system(size: 13, weight: .semibold, design: .rounded)
        case .tab:
            .system(size: 10, weight: .medium, design: .rounded)
        }
    }
}

// MARK: - Convenience Extensions

public extension Font {
    /// Quick access to amount-styled font.
    static let amount = Typography.font(for: .amount)
    /// Quick access to display font.
    static let display = Typography.font(for: .display)
}

import SwiftUI

// MARK: - Premium Typography System

/// Vade Premium typography — Plus Jakarta Sans for UI, JetBrains Mono for amounts.
///
/// ## Font Stack
/// - **Plus Jakarta Sans** — All UI text (headings, body, labels). Modern, geometric,
///   excellent Turkish glyph support (ı, İ, ş, ç, ö, ü, ğ).
/// - **JetBrains Mono** — Monetary amounts only. Tabular-aligned digits ensure
///   perfect vertical alignment in lists and tables.
///
/// ## Usage
/// ```swift
/// Text("₺1.500,00")
///     .font(Typography.font(for: .amount))
/// ```
public enum Typography {
    /// Semantic role for each text style.
    public enum FontRole: Sendable {
        /// Hero display amount — 40pt Light
        case display
        /// Large display amount — 32pt Light (for cards)
        case displayMedium
        /// Screen titles — 24pt Bold
        case title
        /// Section headers — 18pt SemiBold
        case title2
        /// Row / card titles — 16pt SemiBold
        case headline
        /// Body text — 15pt Regular
        case body
        /// Body text with emphasis — 15pt Medium
        case bodyEmphasis
        /// Monetary amounts — 16pt Medium, monospaced digits with JetBrains Mono
        case amount
        /// Small amounts / secondary values — 14pt Medium, monospaced
        case amountSmall
        /// Caption / secondary text — 13pt Regular
        case caption
        /// Tiny labels — 11pt Medium
        case label
        /// Button text — 16pt SemiBold
        case button
        /// Small button / chip text — 13pt SemiBold
        case buttonSmall
        /// Tab bar item — 10pt Medium
        case tab
    }

    /// Returns a SwiftUI `Font` for the given semantic role.
    public static func font(for role: FontRole) -> Font {
        switch role {
        case .display:
            .custom("PlusJakartaSans-Light", size: 40, relativeTo: .largeTitle)
        case .displayMedium:
            .custom("PlusJakartaSans-Light", size: 32, relativeTo: .title)
        case .title:
            .custom("PlusJakartaSans-Bold", size: 24, relativeTo: .title)
        case .title2:
            .custom("PlusJakartaSans-SemiBold", size: 18, relativeTo: .title2)
        case .headline:
            .custom("PlusJakartaSans-SemiBold", size: 16, relativeTo: .headline)
        case .body:
            .custom("PlusJakartaSans-Regular", size: 15, relativeTo: .body)
        case .bodyEmphasis:
            .custom("PlusJakartaSans-Medium", size: 15, relativeTo: .body)
        case .amount:
            .custom("JetBrainsMono-Medium", size: 16, relativeTo: .body)
        case .amountSmall:
            .custom("JetBrainsMono-Medium", size: 14, relativeTo: .callout)
        case .caption:
            .custom("PlusJakartaSans-Regular", size: 13, relativeTo: .caption)
        case .label:
            .custom("PlusJakartaSans-Medium", size: 11, relativeTo: .caption2)
        case .button:
            .custom("PlusJakartaSans-SemiBold", size: 16, relativeTo: .body)
        case .buttonSmall:
            .custom("PlusJakartaSans-SemiBold", size: 13, relativeTo: .callout)
        case .tab:
            .custom("PlusJakartaSans-Medium", size: 10, relativeTo: .caption2)
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


import SwiftUI

// MARK: - Vade Light Banking Color Palette

/// Premium light colour system inspired by N26 / Revolut / Monzo.
/// Light background with white cards, clean blue accent, and semantic green/red.
/// No xcassets dependency — inline colours only.
public enum ColorTokens {
    // MARK: Background & Surfaces
    /// App-level background — warm off-white (#F5F7FA).
    public static let background = Color(red: 0.961, green: 0.965, blue: 0.980)
    /// Card / list-row surface — pure white (#FFFFFF).
    public static let surface = Color(red: 1.000, green: 1.000, blue: 1.000)
    /// Elevated surfaces (modals, sheets, floating cards) — white with shadow.
    public static let surfaceElevated = Color(red: 1.000, green: 1.000, blue: 1.000)
    /// Standard border / divider (#E5E7EB).
    public static let border = Color(red: 0.898, green: 0.906, blue: 0.922)
    /// Subtle border for inputs / low-emphasis separators (#F3F4F6).
    public static let borderSubtle = Color(red: 0.953, green: 0.957, blue: 0.965)

    // MARK: Text
    /// Primary text (headings, values) — near-black (#111827).
    public static let textPrimary = Color(red: 0.067, green: 0.094, blue: 0.153)
    /// Secondary text (body, descriptions) — medium gray (#4B5563).
    public static let textSecondary = Color(red: 0.294, green: 0.333, blue: 0.388)
    /// Tertiary text (labels, placeholders, metadata) — light gray (#9CA3AF).
    public static let textTertiary = Color(red: 0.612, green: 0.639, blue: 0.686)

    // MARK: Accent — Clean Blue
    /// Primary CTA, active states, selected tabs (#007AFF).
    public static let accent = Color(red: 0.000, green: 0.478, blue: 1.000)
    /// Light accent variant for subtle highlights / backgrounds.
    public static let accentLight = Color(red: 0.000, green: 0.478, blue: 1.000).opacity(0.12)
    /// Dark accent for pressed states (#0061CC).
    public static let accentDark = Color(red: 0.000, green: 0.380, blue: 0.800)

    // MARK: Semantic — Positive (Alacak / Receivable)
    /// Positive / receivable — iOS green (#30D158).
    public static let positive = Color(red: 0.188, green: 0.820, blue: 0.345)
    /// Semi-transparent positive for chip backgrounds.
    public static let positiveLight = Color(red: 0.188, green: 0.820, blue: 0.345).opacity(0.12)

    // MARK: Semantic — Negative (Borç / Payable)
    /// Negative / payable — iOS red (#FF453A).
    public static let negative = Color(red: 1.000, green: 0.271, blue: 0.227)
    /// Semi-transparent negative for chip backgrounds.
    public static let negativeLight = Color(red: 1.000, green: 0.271, blue: 0.227).opacity(0.12)

    // MARK: Chart / Data Viz
    /// Chart blue.
    public static let chartBlue = Color(red: 0.000, green: 0.478, blue: 1.000)
    /// Chart purple.
    public static let chartPurple = Color(red: 0.686, green: 0.322, blue: 0.871)
    /// Chart orange.
    public static let chartOrange = Color(red: 1.000, green: 0.584, blue: 0.000)
    /// Chart teal.
    public static let chartTeal = Color(red: 0.353, green: 0.784, blue: 0.980)
}

// MARK: - Spacing — 4pt Base Grid

public enum Spacing {
    public static let xxxs: CGFloat = 2
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 6
    public static let s: CGFloat = 8
    public static let sm: CGFloat = 10
    public static let m: CGFloat = 12
    public static let ml: CGFloat = 14
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 32
    public static let huge: CGFloat = 40
    public static let massive: CGFloat = 48
}

// MARK: - Corner Radius

public enum Radius {
    /// Subtle rounding for small chips / badges.
    public static let xs: CGFloat = 4
    /// Standard card rounding.
    public static let sm: CGFloat = 6
    /// Medium rounding for grouped surfaces.
    public static let md: CGFloat = 10
    /// Large card / modal rounding.
    public static let lg: CGFloat = 14
    /// Extra-large rounding for hero cards / sheets.
    public static let xl: CGFloat = 18
    /// Pill shape (fully rounded).
    public static let pill: CGFloat = 999
}

// MARK: - Elevation & Shadows

/// Premium shadow system — multi-layered for realism.
/// Inspired by Material Design 3 elevation system.
public enum Elevation {
    /// Shadow values for different elevation levels.
    public struct ShadowStyle: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
        public let opacity: Double

        public init(color: Color = .black, radius: CGFloat, x: CGFloat = 0, y: CGFloat, opacity: Double) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
            self.opacity = opacity
        }
    }

    /// Level 0 — no shadow.
    public static let level0 = ShadowStyle(radius: 0, y: 0, opacity: 0)

    /// Level 1 — subtle, for cards in a list.
    public static let level1 = ShadowStyle(radius: 6, y: 2, opacity: 0.15)

    /// Level 2 — medium, for elevated cards / sheets.
    public static let level2 = ShadowStyle(radius: 10, y: 4, opacity: 0.20)

    /// Level 3 — strong, for modals / floating action.
    public static let level3 = ShadowStyle(radius: 16, y: 6, opacity: 0.25)

    /// Level 4 — prominent, for alerts / top-elevation.
    public static let level4 = ShadowStyle(radius: 24, y: 8, opacity: 0.30)

    /// Apply a shadow to any View using `.shadow()` modifier values.
    public static func shadow(_ style: ShadowStyle) -> some ViewModifier {
        ShadowModifier(style: style)
    }
}

private struct ShadowModifier: ViewModifier {
    let style: Elevation.ShadowStyle
    func body(content: Content) -> some View {
        content
            .shadow(color: style.color.opacity(style.opacity), radius: style.radius, x: style.x, y: style.y)
    }
}

public extension View {
    /// Convenience: apply a pre-defined elevation shadow.
    func elevation(_ style: Elevation.ShadowStyle) -> some View {
        modifier(Elevation.shadow(style))
    }
}

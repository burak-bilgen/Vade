import SwiftUI

// MARK: - Vade Dark Fintech Color Palette

/// Minimalist fintech colour system inspired by N26 / Revolut.
/// Dark-first with a clean blue accent. No xcassets dependency — inline colours only.
public enum ColorTokens {
    // MARK: Background & Surfaces
    /// App-level background — near-black with a subtle cool tint (#0D0D12).
    public static let background = Color(red: 0.051, green: 0.051, blue: 0.071)
    /// Card / list-row surface — slightly lighter than background (#1C1C21).
    public static let surface = Color(red: 0.110, green: 0.110, blue: 0.129)
    /// Elevated surfaces (modals, sheets, floating cards) (#2B2B33).
    public static let surfaceElevated = Color(red: 0.169, green: 0.169, blue: 0.200)
    /// Standard border / divider (#3A3A45).
    public static let border = Color(red: 0.227, green: 0.227, blue: 0.271)
    /// Subtle border for inputs / low-emphasis separators (#2B2B33).
    public static let borderSubtle = Color(red: 0.169, green: 0.169, blue: 0.200)

    // MARK: Text
    /// Primary text (headings, values) — white.
    public static let textPrimary = Color.white
    /// Secondary text (body, descriptions) — white at 70% opacity.
    public static let textSecondary = Color.white.opacity(0.70)
    /// Tertiary text (labels, placeholders, metadata) — white at 40% opacity.
    public static let textTertiary = Color.white.opacity(0.40)

    // MARK: Accent — Clean Blue
    /// Primary CTA, active states, selected tabs (#007AFF).
    public static let accent = Color(red: 0.000, green: 0.478, blue: 1.000)
    /// Light accent variant for subtle highlights / backgrounds.
    public static let accentLight = Color(red: 0.000, green: 0.478, blue: 1.000).opacity(0.15)
    /// Dark accent for pressed states (#0061CC).
    public static let accentDark = Color(red: 0.000, green: 0.380, blue: 0.800)

    // MARK: Semantic — Positive (Alacak / Receivable)
    /// Positive / receivable — iOS green (#30D158).
    public static let positive = Color(red: 0.188, green: 0.820, blue: 0.345)
    /// Semi-transparent positive for chip backgrounds.
    public static let positiveLight = Color(red: 0.188, green: 0.820, blue: 0.345).opacity(0.15)

    // MARK: Semantic — Negative (Borç / Payable)
    /// Negative / payable — iOS red (#FF453A).
    public static let negative = Color(red: 1.000, green: 0.271, blue: 0.227)
    /// Semi-transparent negative for chip backgrounds.
    public static let negativeLight = Color(red: 1.000, green: 0.271, blue: 0.227).opacity(0.15)

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

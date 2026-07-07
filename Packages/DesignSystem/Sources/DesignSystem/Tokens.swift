import SwiftUI

// MARK: - Premium Vade Color Palette

/// Vade Premium — dark-first colour system inspired by modern fintech (Revolut, N26, Monzo).
/// All colours are defined in `Colors.xcassets` with light/dark variants.
/// Never hardcode `Color(red:green:blue:)` in views — always use these semantic tokens.
public enum ColorTokens {
    // MARK: Background & Surfaces
    /// App-level background — deep near-black with a subtle cool tint.
    public static let background = Color("background", bundle: .module)
    /// Card / list-row surface — slightly lighter than background.
    public static let surface = Color("surface", bundle: .module)
    /// Elevated surfaces (modals, sheets, floating cards) — one step above surface.
    public static let surfaceElevated = Color("surfaceElevated", bundle: .module)
    /// Standard border / divider.
    public static let border = Color("border", bundle: .module)
    /// Subtle border for inputs / low-emphasis separators.
    public static let borderSubtle = Color("borderSubtle", bundle: .module)

    // MARK: Text
    /// Primary text (headings, important values).
    public static let textPrimary = Color("textPrimary", bundle: .module)
    /// Secondary text (body content, descriptions).
    public static let textSecondary = Color("textSecondary", bundle: .module)
    /// Tertiary text (labels, placeholders, metadata).
    public static let textTertiary = Color("textTertiary", bundle: .module)

    // MARK: Accent — Premium Gold
    /// Primary CTA, active states, selected tabs — premium gold.
    public static let accent = Color("accent", bundle: .module)
    /// Light accent variant for subtle highlights, backgrounds.
    public static let accentLight = Color("accentLight", bundle: .module)
    /// Dark accent for pressed states, active backgrounds.
    public static let accentDark = Color("accentDark", bundle: .module)

    // MARK: Semantic — Positive (Alacak / Receivable)
    /// Positive / receivable — fintech green.
    public static let positive = Color("positive", bundle: .module)
    /// Semi-transparent positive for chip backgrounds.
    public static let positiveLight = Color("positiveLight", bundle: .module)

    // MARK: Semantic — Negative (Borç / Payable)
    /// Negative / payable — alert red.
    public static let negative = Color("negative", bundle: .module)
    /// Semi-transparent negative for chip backgrounds.
    public static let negativeLight = Color("negativeLight", bundle: .module)

    // MARK: Chart / Data Viz
    public static let chartBlue = Color("chartBlue", bundle: .module)
    public static let chartPurple = Color("chartPurple", bundle: .module)
    public static let chartOrange = Color("chartOrange", bundle: .module)
    public static let chartTeal = Color("chartTeal", bundle: .module)
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
    public static let level1 = ShadowStyle(radius: 6, y: 2, opacity: 0.08)

    /// Level 2 — medium, for elevated cards / sheets.
    public static let level2 = ShadowStyle(radius: 10, y: 4, opacity: 0.12)

    /// Level 3 — strong, for modals / floating action.
    public static let level3 = ShadowStyle(radius: 16, y: 6, opacity: 0.16)

    /// Level 4 — prominent, for alerts / top-elevation.
    public static let level4 = ShadowStyle(radius: 24, y: 8, opacity: 0.2)

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

// MARK: - Glassmorphism

/// Glassmorphism surface style — translucent with blur, for premium card effects.
public enum GlassStyle {
    /// Standard glass effect for cards over gradients/images.
    public static let standard = GlassConfig(tint: .white.opacity(0.05), blur: 20)

    /// Stronger glass for elevated overlays.
    public static let strong = GlassConfig(tint: .white.opacity(0.08), blur: 30)

    /// Subtle glass for secondary surfaces.
    public static let subtle = GlassConfig(tint: .white.opacity(0.03), blur: 12)
}

/// Configuration for glassmorphism effect.
public struct GlassConfig: Sendable {
    public let tint: Color
    public let blur: CGFloat

    public init(tint: Color, blur: CGFloat) {
        self.tint = tint
        self.blur = blur
    }

    public func apply<V: View>(to content: V) -> some View {
        content
            .background(tint)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

public extension View {
    /// Apply glassmorphism effect with the given configuration.
    /// - Parameter config: The glass configuration to apply.
    /// - Returns: A view with the glass effect applied.
    @ViewBuilder
    func glass(_ config: GlassConfig = GlassStyle.standard) -> some View {
        config.apply(to: self)
    }
}

import SwiftUI

// MARK: - Color Tokens

/// Modern fintech color system. All colors defined in Colors.xcassets with light/dark variants.
/// Use these semantic tokens — never hardcode Color(red:green:blue:) in views.
public enum ColorTokens {
    // Background & Surfaces
    public static let background = Color("background", bundle: .module)
    public static let surface = Color("surface", bundle: .module)
    public static let border = Color("border", bundle: .module)

    // Text
    public static let textPrimary = Color("textPrimary", bundle: .module)
    public static let textSecondary = Color("textSecondary", bundle: .module)
    public static let textTertiary = Color("textTertiary", bundle: .module)

    // Accent (primary CTA, active states, selected tabs)
    public static let accent = Color("accent", bundle: .module)
    public static let accentLight = Color("accentLight", bundle: .module)

    // Semantic — Positive (alacak/receivable)
    public static let positive = Color("positive", bundle: .module)
    public static let positiveLight = Color("positiveLight", bundle: .module)

    // Semantic — Negative (borç/payable)
    public static let negative = Color("negative", bundle: .module)
    public static let negativeLight = Color("negativeLight", bundle: .module)
}

// MARK: - Spacing (8pt grid)

public enum Spacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

public enum Radius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let pill: CGFloat = 999
}

// MARK: - Elevation (subtle, modern)

public enum Elevation {
    /// Subtle card shadow — only on main summary card
    public static let cardShadow: Color = .black.opacity(0.04)
    public static let cardShadowY: CGFloat = 2
    public static let cardShadowBlur: CGFloat = 8
}

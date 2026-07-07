import SwiftUI

public enum ColorTokens {
    // MARK: Background & Surfaces
    public static let background = Color(red: 0.965, green: 0.969, blue: 0.976)
    public static let surface = Color(red: 1.000, green: 1.000, blue: 1.000)
    public static let surfaceElevated = Color(red: 1.000, green: 1.000, blue: 1.000)
    public static let border = Color(red: 0.902, green: 0.910, blue: 0.925)
    public static let borderSubtle = Color(red: 0.949, green: 0.953, blue: 0.961)

    // MARK: Text
    public static let textPrimary = Color(red: 0.071, green: 0.094, blue: 0.149)
    public static let textSecondary = Color(red: 0.322, green: 0.345, blue: 0.392)
    public static let textTertiary = Color(red: 0.616, green: 0.643, blue: 0.690)

    // MARK: Accent
    public static let accent = Color(red: 0.067, green: 0.373, blue: 0.949)
    public static let accentLight = Color(red: 0.067, green: 0.373, blue: 0.949).opacity(0.12)
    public static let accentDark = Color(red: 0.051, green: 0.282, blue: 0.718)

    // MARK: Semantic
    public static let positive = Color(red: 0.212, green: 0.757, blue: 0.373)
    public static let positiveLight = Color(red: 0.212, green: 0.757, blue: 0.373).opacity(0.12)
    public static let negative = Color(red: 0.957, green: 0.263, blue: 0.212)
    public static let negativeLight = Color(red: 0.957, green: 0.263, blue: 0.212).opacity(0.12)
    public static let warning = Color(red: 1.000, green: 0.561, blue: 0.071)
    public static let warningLight = Color(red: 1.000, green: 0.561, blue: 0.071).opacity(0.12)

    // MARK: Chart
    public static let chartBlue = Color(red: 0.067, green: 0.373, blue: 0.949)
    public static let chartPurple = Color(red: 0.612, green: 0.259, blue: 0.859)
    public static let chartOrange = Color(red: 1.000, green: 0.561, blue: 0.071)
    public static let chartTeal = Color(red: 0.227, green: 0.761, blue: 0.749)
    public static let chartPink = Color(red: 0.898, green: 0.275, blue: 0.518)

    // MARK: Card Gradients
    public static let cardBlue = Color(red: 0.067, green: 0.373, blue: 0.949)
    public static let cardBlueDark = Color(red: 0.035, green: 0.196, blue: 0.498)
    public static let cardGreen = Color(red: 0.212, green: 0.757, blue: 0.373)
    public static let cardGreenDark = Color(red: 0.110, green: 0.392, blue: 0.192)
    public static let cardPurple = Color(red: 0.612, green: 0.259, blue: 0.859)
    public static let cardPurpleDark = Color(red: 0.318, green: 0.133, blue: 0.447)
}

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

public enum Radius {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 6
    public static let md: CGFloat = 10
    public static let lg: CGFloat = 14
    public static let xl: CGFloat = 18
    public static let xxl: CGFloat = 24
    public static let pill: CGFloat = 999
}

public enum Elevation {
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

    public static let level0 = ShadowStyle(radius: 0, y: 0, opacity: 0)
    public static let level1 = ShadowStyle(radius: 6, y: 2, opacity: 0.15)
    public static let level2 = ShadowStyle(radius: 12, y: 4, opacity: 0.20)
    public static let level3 = ShadowStyle(radius: 20, y: 6, opacity: 0.25)
    public static let level4 = ShadowStyle(radius: 28, y: 8, opacity: 0.30)

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
    func elevation(_ style: Elevation.ShadowStyle) -> some View {
        modifier(Elevation.shadow(style))
    }
}

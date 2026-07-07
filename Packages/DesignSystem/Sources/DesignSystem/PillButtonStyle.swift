import SwiftUI

// MARK: - Primary Button Style

public struct PrimaryPillButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.font(for: .button))
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.ml)
            .background(Capsule().fill(ColorTokens.textPrimary))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Brass (CTA) Button Style

public struct BrassPillButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.font(for: .button))
            .foregroundStyle(.black)
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.ml)
            .background(Capsule().fill(ColorTokens.accent))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

public struct SecondaryPillButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.font(for: .button))
            .foregroundStyle(ColorTokens.textPrimary)
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.ml)
            .background(Capsule().stroke(ColorTokens.textPrimary, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Convenience

public extension ButtonStyle where Self == PrimaryPillButtonStyle {
    static var primaryPill: PrimaryPillButtonStyle { PrimaryPillButtonStyle() }
}

public extension ButtonStyle where Self == BrassPillButtonStyle {
    static var brassPill: BrassPillButtonStyle { BrassPillButtonStyle() }
}

public extension ButtonStyle where Self == SecondaryPillButtonStyle {
    static var secondaryPill: SecondaryPillButtonStyle { SecondaryPillButtonStyle() }
}

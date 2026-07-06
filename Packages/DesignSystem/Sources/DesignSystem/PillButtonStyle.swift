import SwiftUI

// MARK: - Primary Button Style

public struct PrimaryPillButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.font(for: .headline))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)
            .background(Capsule().fill(Color.vdInk900))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

// MARK: - Brass (CTA) Button Style

public struct BrassPillButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.font(for: .headline))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)
            .background(Capsule().fill(Color.vdBrass500))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

// MARK: - Secondary Button Style

public struct SecondaryPillButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.font(for: .headline))
            .foregroundColor(Color.vdInk900)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)
            .background(Capsule().stroke(Color.vdInk900, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.6 : 1.0)
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

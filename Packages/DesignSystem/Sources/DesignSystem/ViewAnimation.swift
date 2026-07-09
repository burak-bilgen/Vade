import SwiftUI

// MARK: - Entrance Animation

public enum EntranceDirection {
    case up, down, leading, trailing, scale, fade
}

/// A view modifier that animates a view in when it first appears,
/// with configurable delay, direction, and duration.
public struct EntranceAnimation: ViewModifier {
    let delay: Double
    let direction: EntranceDirection
    let duration: Double

    @State private var appeared = false

    public init(delay: Double = 0, direction: EntranceDirection = .up, duration: Double = 0.5) {
        self.delay = delay
        self.direction = direction
        self.duration = duration
    }

    public func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .blur(radius: appeared ? 0 : 2)
            .scaleEffect(appeared ? 1 : direction == .scale ? 0.85 : 1)
            .offset(
                x: appeared ? 0 : xOffset,
                y: appeared ? 0 : yOffset
            )
            .animation(
                .spring(response: duration, dampingFraction: 0.75, blendDuration: 0.3)
                .delay(delay),
                value: appeared
            )
            .task { @MainActor in
                try? await Task.sleep(nanoseconds: 50_000_000)
                appeared = true
            }
    }

    private var xOffset: CGFloat {
        switch direction {
        case .leading: return -30
        case .trailing: return 30
        default: return 0
        }
    }

    private var yOffset: CGFloat {
        switch direction {
        case .up: return 24
        case .down: return -24
        default: return 0
        }
    }
}

public extension View {
    /// Adds a premium entrance animation - fades in + slides from direction.
    func entrance(
        _ direction: EntranceDirection = .up,
        delay: Double = 0,
        duration: Double = 0.5
    ) -> some View {
        modifier(EntranceAnimation(delay: delay, direction: direction, duration: duration))
    }
}

// MARK: - Staggered List Animation

/// Animates list/row items in one by one with a cascade effect.
public struct StaggeredList<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let content: (Item, Int) -> Content

    public init(
        items: [Item],
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping (Item, Int) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                content(item, i)
                    .entrance(.up, delay: Double(i) * 0.06, duration: 0.4)
            }
        }
    }
}

// MARK: - Shimmer Loading

/// A shimmering skeleton loading placeholder - animates a gradient across the shape.
public struct ShimmerView: View {
    let cornerRadius: CGFloat
    @State private var isAnimating = false

    public init(cornerRadius: CGFloat = Radius.md) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(ColorTokens.border.opacity(0.5))
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.08),
                            .clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: isAnimating ? geo.size.width : -geo.size.width * 0.5)
                    .blur(radius: 12)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Shimmer Skeleton Card

public struct SkeletonCard: View {
    let lines: Int

    public init(lines: Int = 3) {
        self.lines = lines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            ShimmerView(cornerRadius: Radius.sm)
                .frame(width: 100, height: 14)

            ForEach(0..<lines, id: \.self) { i in
                ShimmerView(cornerRadius: Radius.xs)
                    .frame(height: 12)
                    .frame(width: i == lines - 1 ? 160 : nil, alignment: .leading)
            }
        }
        .padding(Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .elevation(Elevation.level1)
    }
}

// MARK: - Dashboard Loading Skeleton

public struct DashboardSkeleton: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                // Balance card skeleton
                SkeletonCard(lines: 3)
                    .frame(height: 180)
                    .padding(.horizontal, Spacing.xl)

                // Quick actions skeleton
                HStack(spacing: Spacing.m) {
                    ForEach(0..<3, id: \.self) { _ in
                        ShimmerView(cornerRadius: Radius.md)
                            .frame(height: 90)
                    }
                }
                .padding(.horizontal, Spacing.xl)

                // Section skeletons
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCard(lines: 3)
                        .padding(.horizontal, Spacing.xl)
                }
            }
            .padding(.vertical, Spacing.l)
        }
    }
}

// MARK: - Press Scale Button Style

/// A more premium press effect with spring bounce.
public struct PremiumPressStyle: ButtonStyle {
    let scale: CGFloat
    let opacity: CGFloat

    public init(scale: CGFloat = 0.94, opacity: CGFloat = 0.9) {
        self.scale = scale
        self.opacity = opacity
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

public extension View {
    /// Applies a premium press animation with spring bounce.
    func premiumPress(scale: CGFloat = 0.94, opacity: CGFloat = 0.9) -> some View {
        buttonStyle(PremiumPressStyle(scale: scale, opacity: opacity))
    }
}

// MARK: - Number Transition

public extension View {
    /// Applies `.contentTransition(.numericText())` only on platforms that support it.
    /// Falls back to identity transition on macOS < 13 or other hosts.
    func countingTransition() -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return AnyView(self.contentTransition(.numericText()))
        }
        #endif
        return AnyView(self)
    }
}

import SwiftUI

// MARK: - Skeleton Loading View

/// Shimmer placeholder shown while content loads.
/// Telegram-style animated gradient skeleton with smooth horizontal sweep.
public struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    @State private var phase: CGFloat = -1

    public init(width: CGFloat? = nil, height: CGFloat = 16, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(ColorTokens.border.opacity(0.6))
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geometry in
                    Color.white.opacity(0.3)
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: phase * (geometry.size.width + geometry.size.width * 0.6))
                        .mask(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        )
                }
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Skeleton Card

/// Pre-built skeleton card matching SummaryCard layout.
public struct SkeletonSummaryCard: View {
    public init() {}

    public var body: some View {
        VStack(spacing: Spacing.l) {
            SkeletonView(width: 100, height: 12)
            SkeletonView(width: 160, height: 28)
            SkeletonView(width: 40, height: 2)
            HStack(spacing: Spacing.xxl) {
                VStack(spacing: Spacing.xs) {
                    SkeletonView(width: 80, height: 10)
                    SkeletonView(width: 60, height: 18)
                }
                VStack(spacing: Spacing.xs) {
                    SkeletonView(width: 80, height: 10)
                    SkeletonView(width: 60, height: 18)
                }
            }
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(ColorTokens.border, lineWidth: 1)
        )
    }
}

// MARK: - Skeleton Row

/// Pre-built skeleton row matching LedgerRowView layout.
public struct SkeletonRow: View {
    public init() {}

    public var body: some View {
        HStack(spacing: Spacing.m) {
            Circle()
                .fill(ColorTokens.border.opacity(0.6))
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonView(width: 120, height: 14)
                SkeletonView(width: 80, height: 10)
            }
            Spacer()
            SkeletonView(width: 60, height: 16)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

// MARK: - Shimmer Modifier

public extension View {
    /// Applies a shimmer animation overlay when `active` is true.
    /// Use during data loading to indicate placeholder content.
    func shimmering(active: Bool) -> some View {
        self
            .redacted(reason: active ? .placeholder : [])
            .overlay {
                if active {
                    ColorTokens.border.opacity(0.3)
                }
            }
            .disabled(active)
    }
}

#Preview {
    VStack(spacing: 24) {
        SkeletonSummaryCard()
        VStack(spacing: 0) {
            SkeletonRow()
            SkeletonRow()
            SkeletonRow()
        }
    }
    .padding()
    .background(ColorTokens.background)
}

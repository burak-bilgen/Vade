import SwiftUI

// MARK: - Skeleton Loading View

/// Shimmer placeholder shown while content loads.
/// Telegram-style animated gradient skeleton.
public struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    public init(width: CGFloat? = nil, height: CGFloat = 16, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.vdHairline.opacity(0.6))
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geometry in
                    Color.white.opacity(0.3)
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: shimmerOffset(geometry.size.width))
                        .mask(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        )
                }
            )
            .clipped()
    }

    private func shimmerOffset(_ containerWidth: CGFloat) -> CGFloat {
        // Animate shimmer from -width to +width
        containerWidth * 1.0
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
                .fill(Color.vdSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.vdHairline, lineWidth: 1)
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
                .fill(Color.vdHairline.opacity(0.6))
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

// MARK: - Shimmer Modifier (iOS 18 optimized)

public extension View {
    func shimmering(active: Bool) -> some View {
        self
            .overlay {
                if active {
                    GeometryReader { _ in
                        Color.white.opacity(0.01)
                    }
                }
            }
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
    .background(Color.vdBackground)
}

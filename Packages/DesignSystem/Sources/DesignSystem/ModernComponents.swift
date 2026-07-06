import SwiftUI
import Core

// MARK: - Quick Action Button

/// Modern pill-style action button with icon, used in Dashboard quick actions row.
public struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    public init(icon: String, label: String, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(ColorTokens.accent)
                    .frame(width: 44, height: 44)
                    .background(ColorTokens.accent.opacity(0.1))
                    .clipShape(.rect(cornerRadius: Radius.md))

                Text(label)
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s)
        }
    }
}

// MARK: - Avatar View

/// Person avatar showing initials on colored background.
public struct AvatarView: View {
    let name: String
    let size: CGFloat

    public init(name: String, size: CGFloat = 40) {
        self.name = name
        self.size = size
    }

    private var initials: String {
        name.components(separatedBy: .whitespaces)
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    private var color: Color {
        let colors: [Color] = [
            ColorTokens.accent,
            ColorTokens.positive,
            ColorTokens.negative,
            ColorTokens.accentLight,
        ]
        let hash = name.utf8.reduce(0) { $0 + Int($1) }
        return colors[hash % colors.count]
    }

    public var body: some View {
        Text(verbatim: initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.opacity(0.75))
            .clipShape(.circle)
    }
}

// MARK: - Balance Chip

/// Compact balance display chip — positive/negative coloring.
public struct BalanceChip: View {
    let amount: Decimal
    let isPositive: Bool

    public init(amount: Decimal, isPositive: Bool) {
        self.amount = amount
        self.isPositive = isPositive
    }

    public var body: some View {
        HStack(spacing: 2) {
            Text(isPositive
                ? "+\(amount.formatted())"
                : "-\(amount.formatted())"
            )
            .font(Typography.font(for: .amount))
            .foregroundStyle(isPositive
                ? ColorTokens.positive
                : ColorTokens.negative
            )
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs)
        .background(
            (isPositive ? ColorTokens.positiveLight : ColorTokens.negativeLight)
                .opacity(0.15)
        )
        .clipShape(.rect(cornerRadius: Radius.sm))
    }
}

// MARK: - Section Header

/// Modern section header with optional action button.
public struct SectionHeader: View {
    let title: String
    var action: (() -> Void)?

    public init(_ title: String, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
            Spacer()
            if let action {
                Button(String(localized: "common.seeAll"), action: action)
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.accent)
            }
        }
    }
}

// MARK: - Metric Tile

/// Single metric tile for dashboard stats.
public struct MetricTile: View {
    let label: String
    let value: Decimal
    let color: Color

    public init(label: String, value: Decimal, color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(value.formatted())
                .font(Typography.font(for: .amount))
                .foregroundStyle(color)
            Text(label)
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(ColorTokens.surface)
        .clipShape(.rect(cornerRadius: Radius.md))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            QuickActionButton(icon: "person.badge.plus", label: "Kişi Ekle") {}
            QuickActionButton(icon: "plus.circle", label: "Borç Ekle") {}
            QuickActionButton(icon: "chart.bar", label: "Grafikler") {}
        }
        .padding()

        HStack(spacing: 12) {
            AvatarView(name: "Ahmet Yılmaz", size: 40)
            AvatarView(name: "Ayşe Demir", size: 40)
            AvatarView(name: "Mehmet Kaya", size: 40)
        }

        HStack(spacing: 12) {
            BalanceChip(amount: 1500, isPositive: true)
            BalanceChip(amount: 800, isPositive: false)
        }

        HStack(spacing: 12) {
            MetricTile(label: "Toplam Alacak", value: 12500, color: ColorTokens.positive)
            MetricTile(label: "Toplam Borç", value: 4800, color: ColorTokens.negative)
        }
        .padding(.horizontal)
    }
    .background(ColorTokens.background)
}

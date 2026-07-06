import SwiftUI
import Core

// MARK: - Avatar View

public struct AvatarView: View {
    let name: String
    let size: CGFloat

    public init(name: String, size: CGFloat = 40) {
        self.name = name
        self.size = size
    }

    private var initials: String {
        name.components(separatedBy: .whitespaces)
            .prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    private var hue: Double {
        Double(name.utf8.reduce(0) { $0 + Int($1) } % 360) / 360.0
    }

    public var body: some View {
        Text(verbatim: initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hue: hue, saturation: 0.5, brightness: 0.7))
            .clipShape(.circle)
    }
}

// MARK: - Balance Chip

public struct BalanceChip: View {
    let amount: Decimal
    let isPositive: Bool

    public init(amount: Decimal, isPositive: Bool) {
        self.amount = amount
        self.isPositive = isPositive
    }

    public var body: some View {
        Text(isPositive ? "+\(amount.formatted())" : "-\(amount.formatted())")
            .font(Typography.font(for: .amount))
            .foregroundStyle(isPositive ? ColorTokens.positive : ColorTokens.negative)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background((isPositive ? ColorTokens.positiveLight : ColorTokens.negativeLight).opacity(0.12), in: .rect(cornerRadius: Radius.sm))
    }
}

// MARK: - Metric Tile

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
            Text(value, format: .number.precision(.fractionLength(2)))
                .font(Typography.font(for: .amount)).foregroundStyle(color)
            Text(label)
                .font(Typography.font(for: .caption)).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(ColorTokens.surface, in: .rect(cornerRadius: Radius.md))
    }
}

// MARK: - Section Header

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
            Spacer()
            if let action {
                Button(String(localized: "common.seeAll"), action: action)
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.accent)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            AvatarView(name: "Ahmet Yılmaz", size: 40)
            AvatarView(name: "Ayşe Demir", size: 40)
            AvatarView(name: "Mehmet Kaya", size: 40)
        }
        HStack(spacing: 12) {
            BalanceChip(amount: 1500, isPositive: true)
            BalanceChip(amount: 800, isPositive: false)
        }
        MetricTile(label: "Alacak", value: 12500, color: ColorTokens.positive)
        SectionHeader("Yaklaşan Ödemeler")
    }
    .padding()
    .background(ColorTokens.background)
}

import SwiftUI

public struct StatChip: View {
    let label: LocalizedStringKey
    let amount: Decimal
    let color: Color

    public init(label: LocalizedStringKey, amount: Decimal, color: Color) {
        self.label = label
        self.amount = amount
        self.color = color
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(label)
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textSecondary)
            Text(amount.formatted())
                .font(Typography.font(for: .amount))
                .foregroundStyle(color)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(RoundedRectangle(cornerRadius: Radius.sm).fill(color.opacity(0.1)))
    }
}

#if DEBUG
#Preview {
    VStack {
        StatChip(label: "Total Receivable", amount: 15000, color: ColorTokens.positive)
        StatChip(label: "Total Payable", amount: 8500, color: ColorTokens.negative)
    }
}
#endif

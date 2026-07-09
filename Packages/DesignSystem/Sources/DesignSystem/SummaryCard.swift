import SwiftUI
import Core
import Domain

public struct SummaryCard: View {
    let netAmount: Decimal
    let totalReceivable: Decimal
    let totalPayable: Decimal

    public init(netAmount: Decimal, totalReceivable: Decimal, totalPayable: Decimal) {
        self.netAmount = netAmount
        self.totalReceivable = totalReceivable
        self.totalPayable = totalPayable
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top accent stripe - subtle indicator of net position
            Rectangle()
                .fill(stripeColor)
                .frame(height: 3)

            VStack(spacing: Spacing.l) {
                // "Net Durum" label
                Text("dashboard.summary.netBalance", comment: "Summary card title")
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textTertiary)

                // Large net amount
                Text(netAmount.formatted())
                    .font(Typography.font(for: .display))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .minimumScaleFactor(0.8)

                // Bottom stats
                HStack(spacing: Spacing.xxl) {
                    statView(
                        prefix: "\u{2191}",
                        label: "dashboard.summary.totalReceivable",
                        amount: totalReceivable,
                        color: ColorTokens.positive
                    )
                    statView(
                        prefix: "\u{2193}",
                        label: "dashboard.summary.totalPayable",
                        amount: totalPayable,
                        color: ColorTokens.negative
                    )
                }
            }
            .padding(Spacing.l)
        }
        .background(ColorTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .elevation(Elevation.level1)
    }

    private var stripeColor: Color {
        if netAmount.isEffectivelyZero { return ColorTokens.accent }
        return netAmount > 0 ? ColorTokens.positive : ColorTokens.negative
    }

    private func statView(prefix: String, label: LocalizedStringKey, amount: Decimal, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            (Text(prefix) + Text(" ") + Text(label))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
            Text(amount.formatted())
                .font(Typography.font(for: .amount))
                .foregroundStyle(color)
                .minimumScaleFactor(0.85)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.l) {
        SummaryCard(netAmount: 2500, totalReceivable: 5000, totalPayable: 2500)
        SummaryCard(netAmount: -800, totalReceivable: 1000, totalPayable: 1800)
        SummaryCard(netAmount: 0, totalReceivable: 0, totalPayable: 0)
    }
    .padding()
    .background(ColorTokens.background)
}

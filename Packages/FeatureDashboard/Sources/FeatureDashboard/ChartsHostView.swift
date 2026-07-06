import SwiftUI
import DesignSystem
import Networking

// MARK: - Charts Host View

/// Host view that renders NetBalanceChart and DirectionPieChart with real data
/// from the dashboard, plus an exchange-rate staleness indicator.
public struct ChartsHostView: View {
    let totalReceivable: Decimal
    let totalPayable: Decimal
    let netBalance: Decimal

    @State private var lastRateUpdateInfo: String?

    public init(totalReceivable: Decimal, totalPayable: Decimal, netBalance: Decimal) {
        self.totalReceivable = totalReceivable
        self.totalPayable = totalPayable
        self.netBalance = netBalance
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Stat chips row
                HStack(spacing: Spacing.m) {
                    StatChip(
                        label: String(localized: "dashboard.summary.totalReceivable"),
                        amount: totalReceivable,
                        color: ColorTokens.positive
                    )
                    StatChip(
                        label: String(localized: "dashboard.summary.totalPayable"),
                        amount: totalPayable,
                        color: ColorTokens.negative
                    )
                }

                // Net balance chart
                let netDataPoints: [ChartDataPoint] = [
                    ChartDataPoint(
                        label: String(localized: "charts.direction.receivable"),
                        value: totalReceivable,
                        color: ColorTokens.positive
                    ),
                    ChartDataPoint(
                        label: String(localized: "charts.direction.payable"),
                        value: totalPayable,
                        color: ColorTokens.negative
                    ),
                ]

                NetBalanceChart(dataPoints: netDataPoints, netBalance: netBalance)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(ColorTokens.surface))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(ColorTokens.border, lineWidth: 1))

                // Direction pie chart
                DirectionPieChart(receivable: totalReceivable, payable: totalPayable)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(ColorTokens.surface))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(ColorTokens.border, lineWidth: 1))

                // Exchange rate staleness indicator
                if let info = lastRateUpdateInfo {
                    Text(info)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(Spacing.l)
        }
        .background(ColorTokens.background)
        .navigationTitle(String(localized: "dashboard.viewStatistics"))
        .task {
            await loadRateStaleness()
        }
    }

    private func loadRateStaleness() async {
        let client = ExchangeRateClient()
        guard let lastDate = await client.lastUpdateDate() else { return }
        let elapsed = Date().timeIntervalSince(lastDate)
        let hours = Int(elapsed / 3600)
        if hours >= 1 {
            let format = String(localized: "exchangeRate.stale")
            lastRateUpdateInfo = String(format: format, hours)
        } else {
            lastRateUpdateInfo = nil
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ChartsHostView(totalReceivable: 15000, totalPayable: 8500, netBalance: 6500)
    }
}
#endif

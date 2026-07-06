import SwiftUI
import DesignSystem

#if canImport(Charts)
import Charts
#endif

// MARK: - Chart Data Point

public struct ChartDataPoint: Identifiable, Sendable {
    public let id = UUID()
    public let label: String
    public let value: Decimal
    public let color: Color

    public init(label: String, value: Decimal, color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - Net Balance Sparkline

public struct NetBalanceChart: View {
    let dataPoints: [ChartDataPoint]
    let netBalance: Decimal

    public init(dataPoints: [ChartDataPoint], netBalance: Decimal) {
        self.dataPoints = dataPoints
        self.netBalance = netBalance
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.netBalance.title"))
                .font(Typography.font(for: .title2))
                .foregroundColor(Color.vdInk900)

            #if canImport(Charts)
            Chart(dataPoints) { point in
                BarMark(
                    x: .value("Label", point.label),
                    y: .value("Value", NSDecimalNumber(decimal: point.value).doubleValue)
                )
                .foregroundStyle(point.color)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            #else
            Text(String(localized: "charts.unavailable"))
                .foregroundColor(Color.vdInk400)
            #endif
        }
    }
}

// MARK: - Receivable vs Payable Pie

public struct DirectionPieChart: View {
    let receivable: Decimal
    let payable: Decimal

    public init(receivable: Decimal, payable: Decimal) {
        self.receivable = receivable
        self.payable = payable
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.direction.title"))
                .font(Typography.font(for: .title2))
                .foregroundColor(Color.vdInk900)

            #if canImport(Charts)
            let data: [ChartDataPoint] = [
                ChartDataPoint(
                    label: String(localized: "charts.direction.receivable"),
                    value: receivable,
                    color: Color.vdPositive600
                ),
                ChartDataPoint(
                    label: String(localized: "charts.direction.payable"),
                    value: payable,
                    color: Color.vdNegative600
                ),
            ]

            Chart(data) { point in
                SectorMark(
                    angle: .value("Value", NSDecimalNumber(decimal: max(point.value, 0.01)).doubleValue),
                    innerRadius: .ratio(0.5),
                    angularInset: 1
                )
                .foregroundStyle(point.color)
            }
            .frame(height: 200)
            #else
            Text(String(localized: "charts.unavailable"))
                .foregroundColor(Color.vdInk400)
            #endif
        }
    }
}

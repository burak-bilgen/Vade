import SwiftUI
import Core

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
        VStack(spacing: Spacing.l) {
            Text(String(localized: "dashboard.summary.netBalance", bundle: .module, comment: "Summary card title"))
                .font(Typography.font(for: .caption))
                .foregroundColor(Color("ink700", bundle: .module))
                .textCase(.uppercase)
            Text(netAmount.formatted())
                .font(Typography.font(for: .display))
                .foregroundColor(netColor)
            Rectangle().fill(Color("brass500", bundle: .module)).frame(width: 40, height: 2)
            HStack(spacing: Spacing.xxl) {
                statView(label: String(localized: "dashboard.summary.totalReceivable", bundle: .module, comment: "Total receivable amount"), amount: totalReceivable,
                         color: Color("positive600", bundle: .module))
                statView(label: String(localized: "dashboard.summary.totalPayable", bundle: .module, comment: "Total payable amount"), amount: totalPayable,
                         color: Color("negative600", bundle: .module))
            }
        }
        .padding(Spacing.xl)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(tintBackground))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color("hairline", bundle: .module), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var netColor: Color {
        if netAmount.isEffectivelyZero { return Color("ink900", bundle: .module) }
        return netAmount > 0 ? Color("positive600", bundle: .module) : Color("negative600", bundle: .module)
    }

    private var tintBackground: Color {
        if netAmount.isEffectivelyZero { return Color("surface", bundle: .module) }
        return netAmount > 0 ? Color("positive100", bundle: .module) : Color("negative100", bundle: .module)
    }

    private func statView(label: String, amount: Decimal, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(label).font(Typography.font(for: .caption)).foregroundColor(Color("ink400", bundle: .module))
            Text(amount.formatted()).font(Typography.font(for: .amount)).foregroundColor(color)
        }
    }
}

#Preview {
    SummaryCard(netAmount: 2500, totalReceivable: 5000, totalPayable: 2500)
        .padding().background(Color("background", bundle: .module))
}

import SwiftUI
import DesignSystem
import Domain

public struct DebtPayoffAssistantSheet: View {
    @Environment(\.dismiss) private var dismiss
    let debts: [DebtRecord]
    let rates: ExchangeRateSnapshot?
    
    public init(debts: [DebtRecord], rates: ExchangeRateSnapshot?) {
        self.debts = debts
        self.rates = rates
    }
    
    // Categorize debts based on risk
    private var categorizedDebts: (highRisk: [DebtRecord], currencyRisk: [DebtRecord], standard: [DebtRecord]) {
        let now = Date()
        var high: [DebtRecord] = []
        var curr: [DebtRecord] = []
        var std: [DebtRecord] = []
        
        for debt in debts {
            // High Risk: Overdue or due in less than 3 days
            if let due = debt.dueDate {
                if due < now || Calendar.current.dateComponents([.day], from: now, to: due).day ?? 10 < 3 {
                    high.append(debt)
                    continue
                }
            }
            
            // Currency Risk: Non-TRY debts (USD, EUR, Gold) have exchange rate volatility risk
            if debt.kind != .tryCoin {
                curr.append(debt)
            } else {
                std.append(debt)
            }
        }
        
        return (high, curr, std)
    }
    
    // Helpers to convert to TRY on the fly for statistics
    private func convertToTRY(_ amount: Decimal, from kind: CurrencyKind) -> Decimal {
        guard let rates else { return amount } // Fallback to 1:1 if no rates
        let rate: Decimal = {
            switch kind {
            case .tryCoin: return 1
            case .usd: return rates.usdRate ?? 32.5
            case .eur: return rates.eurRate ?? 35.2
            case .goldGram, .goldQuarter, .goldHalf, .goldFull, .goldRepublic:
                return (rates.goldRate ?? 2450) * kind.gramEquivalent
            }
        }()
        return amount * rate
    }
    
    private func totalTRY(for items: [DebtRecord]) -> Decimal {
        items.reduce(.zero) { $0 + convertToTRY($1.amount, from: $1.kind) }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ColorTokens.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Overview Card
                        VStack(spacing: Spacing.s) {
                            Text("payoff.overview.title")
                                .font(Typography.font(for: .label))
                                .foregroundStyle(ColorTokens.textTertiary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            
                            let total = totalTRY(for: debts)
                            Text(total, format: .currency(code: "TRY"))
                                .font(.custom(AppFont.jakartaBold, size: 32))
                                .foregroundStyle(ColorTokens.textPrimary)
                            
                            Text("payoff.overview.desc")
                                .font(Typography.font(for: .caption))
                                .foregroundStyle(ColorTokens.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.m)
                        }
                        .padding(.vertical, Spacing.xl)
                        
                        // Payoff Strategy Sections
                        VStack(spacing: Spacing.l) {
                            // Category 1: High Risk
                            strategyCard(
                                title: "payoff.highRisk.title",
                                desc: "payoff.highRisk.desc",
                                icon: "exclamationmark.triangle.fill",
                                color: ColorTokens.negative,
                                items: categorizedDebts.highRisk
                            )
                            
                            // Category 2: Currency Volatility
                            strategyCard(
                                title: "payoff.currencyRisk.title",
                                desc: "payoff.currencyRisk.desc",
                                icon: "chart.line.flattrend.xyaxis.circle.fill",
                                color: ColorTokens.chartOrange,
                                items: categorizedDebts.currencyRisk
                            )
                            
                            // Category 3: Standard
                            strategyCard(
                                title: "payoff.standard.title",
                                desc: "payoff.standard.desc",
                                icon: "checkmark.circle.fill",
                                color: ColorTokens.positive,
                                items: categorizedDebts.standard
                            )
                        }
                        .padding(.horizontal, Spacing.xl)
                        
                        // Advisory note
                        Text("payoff.disclaimer")
                            .font(.system(size: 10))
                            .foregroundStyle(ColorTokens.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.s)
                    }
                    .padding(.vertical, Spacing.l)
                }
            }
            .navigationTitle("payoff.title")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done")) {
                        dismiss()
                    }
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.accent)
                }
            }
        }
    }
    
    @ViewBuilder
    private func strategyCard(
        title: String,
        desc: String,
        icon: String,
        color: Color,
        items: [DebtRecord]
    ) -> some View {
        GlassCard(
            title: LocalizedStringKey(title),
            icon: icon,
            accentColor: color
        ) {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text(LocalizedStringKey(desc))
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textSecondary)
                
                HStack {
                    Text("payoff.totalAmount")
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                    Spacer()
                    let total = totalTRY(for: items)
                    Text(total, format: .currency(code: "TRY"))
                        .font(Typography.font(for: .bodyEmphasis))
                        .foregroundStyle(color)
                }
                
                if !items.isEmpty {
                    DashedDivider()
                    
                    VStack(spacing: Spacing.s) {
                        ForEach(items) { item in
                            HStack {
                                Image(systemName: item.direction == .receivable ? "arrow.down.left" : "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
                                
                                Text(item.kind.format(item.amount))
                                    .font(Typography.font(for: .caption).monospacedDigit())
                                    .foregroundStyle(ColorTokens.textPrimary)
                                
                                Spacer()
                                
                                if let due = item.dueDate {
                                    Text(due, style: .date)
                                        .font(.system(size: 10))
                                        .foregroundStyle(ColorTokens.textTertiary)
                                } else {
                                    Text("payoff.noDueDate")
                                        .font(.system(size: 10))
                                        .foregroundStyle(ColorTokens.textTertiary)
                                }
                            }
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("payoff.noDebts")
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                        Spacer()
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
            .padding(.top, Spacing.xs)
        }
    }
}

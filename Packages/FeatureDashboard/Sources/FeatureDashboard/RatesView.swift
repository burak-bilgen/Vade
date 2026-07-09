import SwiftUI
import DesignSystem
import Domain
import Networking

// MARK: - Exchange Rates View

public struct RatesView: View {
    @Environment(\.locale) private var locale
    @State private var rates: ExchangeRateSnapshot?
    @State private var allRates: [(code: String, rate: Decimal)] = []
    @State private var selectedCode: String = "USD"
    @State private var isLoading = true
    @State private var conversionAmount = ""
    private let client = ExchangeRateClient()

    private static let majorCodes: [String] = ["USD", "EUR", "GBP", "CHF", "JPY", "XAU"]

    private var majorRates: [(code: String, rate: Decimal?, label: String)] {
        Self.majorCodes.map { code in
            let label: String = {
                switch code {
                case "USD": return "rates.usd"
                case "EUR": return "rates.eur"
                case "GBP": return "rates.gbp"
                case "CHF": return "rates.chf"
                case "JPY": return "rates.jpy"
                case "XAU": return "currency.gold.gram"
                default: return code
                }
            }()
            return (code, self.rate(for: code), label)
        }
    }

    public init() {}

    public var body: some View {
        ZStack {
            FinanceBackgroundAnimation()
                .ignoresSafeArea()
            ColorTokens.background.opacity(0.12).ignoresSafeArea()

            if isLoading && rates == nil {
                RatesSkeleton()
                    .entrance(.fade)
            } else {
                content
            }
        }
        .navigationTitle(String(localized: "rates.title"))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadRates() }
        .task { await loadRates() }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Selected currency - large prominent card
                if let selectedRate = rate(for: selectedCode) {
                    ProminentRateCard(
                        code: selectedCode == "XAU" ? "GRAM" : selectedCode,
                        rate: selectedCode == "XAU" ? rates?.goldRate : selectedRate,
                        lastUpdate: rates?.lastUpdate
                    )
                    .padding(.horizontal, Spacing.xl)
                    .entrance(.scale, delay: 0.05)
                }

                // Quick converter input
                VStack(spacing: Spacing.m) {
                    HStack(spacing: Spacing.m) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(ColorTokens.textTertiary)

                        Text(String(localized: "rates.converter.title"))
                            .font(Typography.font(for: .label))
                            .foregroundStyle(ColorTokens.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Spacer()
                    }

                    HStack(spacing: Spacing.m) {
                        // Amount input
                        TextField("100", text: $conversionAmount)
                            .font(Typography.font(for: .title))
                            .foregroundStyle(ColorTokens.textPrimary)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)

                        Text(currencyDisplayCode(for: selectedCode == "XAU" ? "GRAM" : selectedCode))
                            .font(Typography.font(for: .bodyEmphasis))
                            .foregroundStyle(ColorTokens.textSecondary)

                        Text("=")
                            .font(Typography.font(for: .title))
                            .foregroundStyle(ColorTokens.textTertiary)

                        if let amount = Decimal(string: conversionAmount.isEmpty ? "0" : conversionAmount),
                           let rate = (selectedCode == "XAU" ? rates?.goldRate : rate(for: selectedCode)) {
                            let result = amount * rate
                            Text(result.formatted())
                                .font(Typography.font(for: .title))
                                .foregroundStyle(ColorTokens.accent)
                                .contentTransition(.numericText())

                            Text(String(localized: "currency.tl"))
                                .font(Typography.font(for: .bodyEmphasis))
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.l)
                    .padding(.vertical, Spacing.ml)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(ColorTokens.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .stroke(ColorTokens.border, lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.1)

                // All currencies - tappable to select
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(String(localized: "rates.major"))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .padding(.horizontal, Spacing.xl)

                    VStack(spacing: 0) {
                        ForEach(Array(majorRates.enumerated()), id: \.element.code) { i, item in
                            RateTileRow(
                                code: item.code,
                                label: LocalizedStringKey(item.label),
                                rate: item.rate,
                                isSelected: item.code == selectedCode
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCode = item.code
                                }
                                HapticFeedback.impact(.light)
                            }
                            if i < majorRates.count - 1 {
                                DashedDivider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                            .fill(ColorTokens.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                            .stroke(ColorTokens.border, lineWidth: 0.5)
                    )
                    .padding(.horizontal, Spacing.xl)
                }
                .entrance(.up, delay: 0.15)

                // All rates section
                if !allRates.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(String(localized: "rates.all"))
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                            .padding(.horizontal, Spacing.xl)

                        VStack(spacing: 0) {
                            ForEach(Array(allRates.enumerated()), id: \.element.code) { i, item in
                                AllRateRow(code: item.code, rate: item.rate)
                                if i < allRates.count - 1 {
                                    DashedDivider()
                                        .padding(.leading, 72)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                                .fill(ColorTokens.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                                .stroke(ColorTokens.border, lineWidth: 0.5)
                        )
                        .padding(.horizontal, Spacing.xl)
                    }
                    .entrance(.up, delay: 0.2)
                }

                // Last update
                if let lastUpdate = rates?.lastUpdate {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(ColorTokens.textTertiary)
                        Text(lastUpdate, format: .dateTime.hour().minute().day().month(.abbreviated))
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .entrance(.fade, delay: 0.25)
                }

                Spacer().frame(height: Spacing.xxxl)
            }
            .padding(.vertical, Spacing.l)
        }
        .background(Color.clear)
        .onChange(of: selectedCode) { _, _ in
            conversionAmount = ""
        }
    }

    private func loadRates() async {
        isLoading = true
        defer { isLoading = false }

        async let usd = try? await client.fetchRate(for: "USD")
        async let eur = try? await client.fetchRate(for: "EUR")
        async let gbp = try? await client.fetchRate(for: "GBP")
        async let chf = try? await client.fetchRate(for: "CHF")
        async let jpy = try? await client.fetchRate(for: "JPY")
        async let gold = try? await client.fetchGoldRatePerGram()

        let (usdRate, eurRate, gbpRate, chfRate, jpyRate, goldRate) = await (usd, eur, gbp, chf, jpy, gold)
        rates = ExchangeRateSnapshot(
            usdRate: usdRate, eurRate: eurRate, goldRate: goldRate,
            gbpRate: gbpRate, chfRate: chfRate, jpyRate: jpyRate,
            lastUpdate: await client.lastUpdateDate()
        )

        if let allData = try? await client.fetchAllRates() {
            allRates = allData
        }
    }

    private func rate(for code: String) -> Decimal? {
        guard let rates else { return nil }
        switch code {
        case "USD": return rates.usdRate
        case "EUR": return rates.eurRate
        case "GBP": return rates.gbpRate
        case "CHF": return rates.chfRate
        case "JPY": return rates.jpyRate
        case "XAU": return rates.goldRate
        default: return nil
        }
    }

    private func currencyDisplayCode(for code: String) -> String {
        switch code {
        case "GRAM": return String(localized: "currency.displayCode.gram", locale: locale)
        case "ÇEYREK", "CEYREK": return String(localized: "currency.displayCode.quarter", locale: locale)
        default: return code
        }
    }
}

// MARK: - Rate Tile Row

private struct RateTileRow: View {
    @Environment(\.locale) private var locale
    let code: String
    let label: LocalizedStringKey
    let rate: Decimal?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.l) {
                CurrencyIconView(code: code, size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currencyDisplayCode(for: code == "XAU" ? "GRAM" : code))
                        .font(Typography.font(for: .bodyEmphasis))
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(label)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                }

                Spacer()

                if let rate {
                    Text(rate, format: .number.precision(.fractionLength(2)))
                        .font(Typography.font(for: .amount))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .contentTransition(.numericText())
                } else {
                    Text("--")
                        .font(Typography.font(for: .amount))
                        .foregroundStyle(ColorTokens.textTertiary)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ColorTokens.accent)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background(isSelected ? ColorTokens.accentLight : Color.clear)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isSelected)
    }

    private func currencyDisplayCode(for code: String) -> String {
        switch code {
        case "GRAM": return String(localized: "currency.displayCode.gram", locale: locale)
        case "ÇEYREK", "CEYREK": return String(localized: "currency.displayCode.quarter", locale: locale)
        default: return code
        }
    }
}

// MARK: - All Rate Row

private struct AllRateRow: View {
    let code: String
    let rate: Decimal

    var body: some View {
        HStack(spacing: Spacing.l) {
            CurrencyIconView(code: code, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(code)
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(currencyDisplayName(for: code))
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Spacer()

            Text(rate, format: .number.precision(.fractionLength(2)))
                .font(Typography.font(for: .amount))
                .foregroundStyle(ColorTokens.textPrimary)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }

    private func currencyDisplayName(for code: String) -> String {
        switch code {
        case "USD": return String(localized: "rates.usd")
        case "EUR": return String(localized: "rates.eur")
        case "GBP": return String(localized: "rates.gbp")
        case "CHF": return String(localized: "rates.chf")
        case "JPY": return String(localized: "rates.jpy")
        default: return code
        }
    }
}

// MARK: - Rates Loading Skeleton

private struct RatesSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                // Section header skeleton
                ShimmerView(cornerRadius: Radius.sm)
                    .frame(width: 100, height: 14)
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, Spacing.l)

                // Rates card skeleton
                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { i in
                        HStack(spacing: Spacing.l) {
                            ShimmerView(cornerRadius: Radius.sm)
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                ShimmerView(cornerRadius: Radius.xs)
                                    .frame(width: 80, height: 12)
                                ShimmerView(cornerRadius: Radius.xs)
                                    .frame(width: 36, height: 10)
                            }
                            Spacer()
                            ShimmerView(cornerRadius: Radius.xs)
                                .frame(width: 60, height: 14)
                        }
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.m)
                        if i < 5 {
                            DashedDivider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .fill(ColorTokens.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .stroke(ColorTokens.border, lineWidth: 0.5)
                )
                .padding(.horizontal, Spacing.l)
            }
            .padding(.vertical, Spacing.l)
        }
    }
}

#Preview {
    NavigationStack { RatesView() }
}

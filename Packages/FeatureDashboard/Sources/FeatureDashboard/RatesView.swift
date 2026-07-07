import SwiftUI
import DesignSystem
import Domain
import Networking

// MARK: - Exchange Rates View

public struct RatesView: View {
    @State private var rates: ExchangeRateSnapshot?
    @State private var allRates: [(code: String, rate: Decimal)] = []
    @State private var isLoading = true
    private let client = ExchangeRateClient()

    private static let majorCurrencies: [(flag: String, code: String, key: String)] = [
        ("🇺🇸", "USD", "rates.usd"),
        ("🇪🇺", "EUR", "rates.eur"),
        ("🇬🇧", "GBP", "rates.gbp"),
        ("🇨🇭", "CHF", "rates.chf"),
        ("🇯🇵", "JPY", "rates.jpy"),
        ("🪙", "XAU", "currency.gold.gram"),
    ]

    public init() {}

    public var body: some View {
        List {
            if let rates {
                Section(String(localized: "rates.major")) {
                    ForEach(Self.majorCurrencies, id: \.code) { currency in
                        rateRow(
                            flag: currency.flag,
                            code: currency.code,
                            label: String(localized: LocalizedStringResource(stringLiteral: currency.key)),
                            rate: self.rate(for: currency.code, snapshot: rates)
                        )
                    }
                }

                if let lastUpdate = rates.lastUpdate {
                    HStack {
                        Image(systemName: "clock")
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                        Text(lastUpdate, format: .dateTime.hour().minute().day().month(.abbreviated))
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                    .listRowBackground(ColorTokens.background)
                }
            }

            if !allRates.isEmpty {
                Section(String(localized: "rates.all")) {
                    ForEach(allRates, id: \.code) { item in
                        HStack(spacing: Spacing.m) {
                            Text(flag(for: item.code))
                                .font(Typography.font(for: .headline))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.code)
                                    .font(Typography.font(for: .bodyEmphasis))
                                    .foregroundStyle(ColorTokens.textPrimary)
                                Text(currencyName(for: item.code))
                                    .font(Typography.font(for: .label))
                                    .foregroundStyle(ColorTokens.textTertiary)
                            }
                            Spacer()
                            Text(item.rate, format: .number.precision(.fractionLength(4)))
                                .font(Typography.font(for: .amount))
                                .foregroundStyle(ColorTokens.textPrimary)
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "rates.title"))
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ColorTokens.background)
        .overlay {
            if isLoading { ProgressView() }
        }
        .refreshable { await loadRates() }
        .task { await loadRates() }
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

    private func rate(for code: String, snapshot: ExchangeRateSnapshot) -> Decimal? {
        switch code {
        case "USD": return snapshot.usdRate
        case "EUR": return snapshot.eurRate
        case "GBP": return snapshot.gbpRate
        case "CHF": return snapshot.chfRate
        case "JPY": return snapshot.jpyRate
        case "XAU": return snapshot.goldRate
        default: return nil
        }
    }

    private func rateRow(flag: String, code: String, label: String, rate: Decimal?) -> some View {
        HStack(spacing: Spacing.l) {
            Text(flag)
                .font(Typography.font(for: .title2))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(code)
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            Spacer()
            if let rate {
                Text(rate, format: .number.precision(.fractionLength(4)))
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(ColorTokens.textPrimary)
            } else {
                Text("--")
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    private func flag(for code: String) -> String {
        switch code {
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "CHF": return "🇨🇭"
        case "JPY": return "🇯🇵"
        case "CAD": return "🇨🇦"
        case "AUD": return "🇦🇺"
        case "CNY": return "🇨🇳"
        case "SEK": return "🇸🇪"
        case "NOK": return "🇳🇴"
        case "DKK": return "🇩🇰"
        case "SAR": return "🇸🇦"
        case "KWD": return "🇰🇼"
        case "BGN": return "🇧🇬"
        case "RON": return "🇷🇴"
        case "RUB": return "🇷🇺"
        case "IRR": return "🇮🇷"
        case "KRW": return "🇰🇷"
        case "ZAR": return "🇿🇦"
        case "BRL": return "🇧🇷"
        case "INR": return "🇮🇳"
        case "MXN": return "🇲🇽"
        case "MYR": return "🇲🇾"
        case "NZD": return "🇳🇿"
        case "PHP": return "🇵🇭"
        case "SGD": return "🇸🇬"
        case "THB": return "🇹🇭"
        case "TRY": return "🇹🇷"
        case "XAU": return "🪙"
        default: return "💱"
        }
    }

    private func currencyName(for code: String) -> String {
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

#Preview {
    NavigationStack { RatesView() }
}

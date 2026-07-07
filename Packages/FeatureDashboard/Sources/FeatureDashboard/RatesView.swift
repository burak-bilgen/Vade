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

    public init() {}

    public var body: some View {
        List {
            // Major rates
            if let rates {
                Section(String(localized: "rates.major")) {
                    rateRow(flag: "🇺🇸", code: "USD", label: "Dolar", rate: rates.usdRate)
                    rateRow(flag: "🇪🇺", code: "EUR", label: "Euro", rate: rates.eurRate)
                    rateRow(flag: "🪙", code: "XAU", label: String(localized: "currency.gold.gram"), rate: rates.goldRate)
                }
            }

            // All currencies
            if !allRates.isEmpty {
                Section(String(localized: "rates.all")) {
                    ForEach(allRates, id: \.code) { item in
                        HStack {
                            Text(item.code)
                                .font(Typography.font(for: .bodyEmphasis))
                            Spacer()
                            Text(item.rate, format: .number.precision(.fractionLength(4)))
                                .font(Typography.font(for: .amountSmall))
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "rates.title"))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.plain)
        #endif
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
        async let gold = try? await client.fetchGoldRatePerGram()

        let (usdRate, eurRate, goldRate) = await (usd, eur, gold)
        rates = ExchangeRateSnapshot(usdRate: usdRate, eurRate: eurRate, goldRate: goldRate, lastUpdate: await client.lastUpdateDate())

        // Fetch all rates via client
        if let allData = try? await client.fetchAllRates() {
            allRates = allData
        }
    }

    private func rateRow(flag: String, code: String, label: String, rate: Decimal?) -> some View {
        HStack(spacing: Spacing.m) {
            Text(flag).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
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
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
    }
}

#Preview {
    NavigationStack { RatesView() }
}

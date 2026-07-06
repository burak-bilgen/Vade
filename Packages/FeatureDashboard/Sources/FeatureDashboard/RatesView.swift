import SwiftUI
import DesignSystem
import Domain
import Networking

// MARK: - Exchange Rates View

public struct RatesView: View {
    @State private var rates: ExchangeRateSnapshot?
    @State private var allRates: [(String, String)] = []
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
                    ForEach(allRates, id: \.0) { (code, value) in
                        HStack {
                            Text(code)
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text(value)
                                .font(.system(size: 15, weight: .regular, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "rates.title"))
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
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

        // Also fetch all rates for detail view
        if let allData = try? await fetchAllRates() {
            allRates = allData
        }
    }

    private func fetchAllRates() async throws -> [(String, String)] {
        let url = URL(string: "https://finans.truncgil.com/v3/today.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return json.compactMap { (key, value) -> (String, String)? in
            guard let dict = value as? [String: Any],
                  let selling = dict["Selling"] as? String,
                  dict["Type"] as? String == "Currency" else { return nil }
            return (key, selling)
        }.sorted { $0.0 < $1.0 }
    }

    private func rateRow(flag: String, code: String, label: String, rate: Decimal?) -> some View {
        HStack(spacing: 12) {
            Text(flag).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 15, weight: .medium))
                Text(code).font(.system(size: 12)).foregroundStyle(.tertiary)
            }
            Spacer()
            if let rate {
                Text(rate, format: .number.precision(.fractionLength(4)))
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
            } else {
                Text("--").foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    NavigationStack { RatesView() }
}

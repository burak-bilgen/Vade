import Foundation
import Domain

// MARK: - Currency Converter

/// Converts debt amounts to TRY equivalents using cached exchange rates.
/// Gold rates: converts grams to TL using gold gram rate.
/// Fiat currencies: converts to TL using TCMB ForexSelling rate.
public final class CurrencyConverter: CurrencyConverting, @unchecked Sendable {
    private let rateProvider: ExchangeRateProviding

    public init(rateProvider: ExchangeRateProviding) {
        self.rateProvider = rateProvider
    }

    public func convertToTRY(amount: Decimal, from currency: CurrencyKind) async throws -> Decimal {
        switch currency {
        case .tryCoin:
            return amount

        case .usd:
            guard let rate = try await rateProvider.fetchRate(for: "USD") else {
                throw ConversionError.rateUnavailable(currency.rawValue)
            }
            return amount * rate

        case .eur:
            guard let rate = try await rateProvider.fetchRate(for: "EUR") else {
                throw ConversionError.rateUnavailable(currency.rawValue)
            }
            return amount * rate

        case .goldGram:
            guard let rate = try await rateProvider.fetchGoldRatePerGram() else {
                throw ConversionError.rateUnavailable("GOLD_GRAM")
            }
            return amount * rate

        case .goldCeyrek:
            guard let rate = try await rateProvider.fetchGoldRatePerGram() else {
                throw ConversionError.rateUnavailable("GOLD_GRAM")
            }
            // 1 çeyrek = 1.75 gram
            return amount * Decimal(175) / Decimal(100) * rate

        case .goldYarim:
            guard let rate = try await rateProvider.fetchGoldRatePerGram() else {
                throw ConversionError.rateUnavailable("GOLD_GRAM")
            }
            // 1 yarım = 3.5 gram
            return amount * Decimal(35) / Decimal(10) * rate

        case .goldTam:
            guard let rate = try await rateProvider.fetchGoldRatePerGram() else {
                throw ConversionError.rateUnavailable("GOLD_GRAM")
            }
            // 1 tam = 7.0 gram
            return amount * 7 * rate

        case .goldCumhuriyet:
            guard let rate = try await rateProvider.fetchGoldRatePerGram() else {
                throw ConversionError.rateUnavailable("GOLD_GRAM")
            }
            // 1 cumhuriyet = 7.216 gram = 7216/1000
            return amount * Decimal(7216) / Decimal(1000) * rate
        }
    }

    public func lastUpdateDate() async -> Date? {
        await rateProvider.lastUpdateDate()
    }
}

// MARK: - Errors

public enum ConversionError: Error, Sendable {
    case rateUnavailable(String)
}

import Foundation
import Domain

// MARK: - Currency Converter

/// Converts debt amounts to TRY equivalents using cached exchange rates.
/// Gold rates: converts grams to TL using gold gram rate.
/// Fiat currencies: converts to TL using TCMB ForexSelling rate.
public final class CurrencyConverter: CurrencyConverting {
    private let rateProvider: ExchangeRateProviding

    public init(rateProvider: ExchangeRateProviding) {
        self.rateProvider = rateProvider
    }

    public func convertToTRY(amount: Decimal, from currency: CurrencyKind) async throws -> Decimal {
        switch currency {
        case .tryCoin:
            return amount
        case .usd:
            return try await convertFiat(amount: amount, code: "USD")
        case .eur:
            return try await convertFiat(amount: amount, code: "EUR")
        case .goldGram, .goldCeyrek, .goldYarim, .goldTam, .goldCumhuriyet:
            return try await convertGold(amount: amount, gramMultiplier: currency.gramEquivalent)
        }
    }

    private func convertFiat(amount: Decimal, code: String) async throws -> Decimal {
        guard let rate = try await rateProvider.fetchRate(for: code) else {
            throw ConversionError.rateUnavailable(code)
        }
        return amount * rate
    }

    private func convertGold(amount: Decimal, gramMultiplier: Decimal) async throws -> Decimal {
        guard let rate = try await rateProvider.fetchGoldRatePerGram() else {
            throw ConversionError.rateUnavailable("GOLD_GRAM")
        }
        return amount * gramMultiplier * rate
    }

    public func lastUpdateDate() async -> Date? {
        await rateProvider.lastUpdateDate()
    }
}

// MARK: - Errors

public enum ConversionError: Error, Sendable {
    case rateUnavailable(String)
}

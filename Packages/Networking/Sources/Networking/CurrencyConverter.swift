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
            return try await convertFiat(amount: amount, code: "USD")
        case .eur:
            return try await convertFiat(amount: amount, code: "EUR")
        case .goldGram:
            return try await convertGold(amount: amount, gramMultiplier: 1)
        case .goldCeyrek:
            return try await convertGold(amount: amount, gramMultiplier: Decimal(175) / Decimal(100))
        case .goldYarim:
            return try await convertGold(amount: amount, gramMultiplier: Decimal(35) / Decimal(10))
        case .goldTam:
            return try await convertGold(amount: amount, gramMultiplier: 7)
        case .goldCumhuriyet:
            return try await convertGold(amount: amount, gramMultiplier: Decimal(7216) / Decimal(1000))
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

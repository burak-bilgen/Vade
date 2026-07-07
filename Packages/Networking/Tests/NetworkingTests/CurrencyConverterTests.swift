import Foundation
import Testing
import Domain
@testable import Networking

// MARK: - Mock Rate Provider

@MainActor
private final class MockRateProvider: ExchangeRateProviding {
    var usdRate: Decimal = 31.5
    var eurRate: Decimal = 35.2
    var goldRate: Decimal = 3450.0
    var shouldFail = false

    func fetchRate(for currency: String) async throws -> Decimal? {
        if shouldFail { throw ExchangeRateError.rateNotFound }
        switch currency {
        case "USD": return usdRate
        case "EUR": return eurRate
        default: return nil
        }
    }

    func fetchGoldRatePerGram() async throws -> Decimal? {
        if shouldFail { throw ExchangeRateError.rateNotFound }
        return goldRate
    }

    func fetchAllRates() async throws -> [(code: String, rate: Decimal)] { [] }

    func lastUpdateDate() async -> Date? { Date() }
}

// MARK: - Currency Converter Tests

@Suite("CurrencyConverter")
@MainActor
struct CurrencyConverterTests {

    @Test("TRY returns same amount (1:1)",
          arguments: [
            Decimal(1000),
            Decimal(500.50),
            Decimal(0),
          ])
    func testTRYNoConversion(amount: Decimal) async throws {
        let converter = CurrencyConverter(rateProvider: MockRateProvider())
        let result = try await converter.convertToTRY(amount: amount, from: .tryCoin)
        #expect(result == amount)
    }

    @Test("USD multiplies by USD/TRY rate",
          arguments: [
            (amount: Decimal(100), rate: Decimal(31.5), expected: Decimal(3150)),
            (amount: Decimal(50), rate: Decimal(30.0), expected: Decimal(1500)),
            (amount: Decimal(1), rate: Decimal(31.0), expected: Decimal(31)),
          ])
    func testUSDConversion(amount: Decimal, rate: Decimal, expected: Decimal) async throws {
        let mock = MockRateProvider()
        mock.usdRate = rate
        let converter = CurrencyConverter(rateProvider: mock)
        let result = try await converter.convertToTRY(amount: amount, from: .usd)
        #expect(result == expected)
    }

    @Test("EUR multiplies by EUR/TRY rate",
          arguments: [
            (amount: Decimal(100), rate: Decimal(35.2), expected: Decimal(3520)),
          ])
    func testEURConversion(amount: Decimal, rate: Decimal, expected: Decimal) async throws {
        let mock = MockRateProvider()
        mock.eurRate = rate
        let converter = CurrencyConverter(rateProvider: mock)
        let result = try await converter.convertToTRY(amount: amount, from: .eur)
        #expect(result == expected)
    }

    @Test("Gold gram converts to TL via gold rate",
          arguments: [
            (grams: Decimal(10), rate: Decimal(3450), expected: Decimal(34500)),
            (grams: Decimal(1), rate: Decimal(3000), expected: Decimal(3000)),
          ])
    func testGoldGramConversion(grams: Decimal, rate: Decimal, expected: Decimal) async throws {
        let mock = MockRateProvider()
        mock.goldRate = rate
        let converter = CurrencyConverter(rateProvider: mock)
        let result = try await converter.convertToTRY(amount: grams, from: .goldGram)
        #expect(result == expected)
    }

    @Test("Gold subtypes use correct gram multipliers",
          arguments: [
            (kind: CurrencyKind.goldQuarter, count: Decimal(1), rate: Decimal(3500), expected: Decimal(6125)),
            (kind: CurrencyKind.goldHalf, count: Decimal(1), rate: Decimal(3500), expected: Decimal(12250)),
            (kind: CurrencyKind.goldFull, count: Decimal(1), rate: Decimal(3500), expected: Decimal(24500)),
            (kind: CurrencyKind.goldRepublic, count: Decimal(1), rate: Decimal(3500), expected: Decimal(25256)),
          ])
    func testGoldSubtypeConversion(kind: CurrencyKind, count: Decimal, rate: Decimal, expected: Decimal) async throws {
        let mock = MockRateProvider()
        mock.goldRate = rate
        let converter = CurrencyConverter(rateProvider: mock)
        let result = try await converter.convertToTRY(amount: count, from: kind)
        #expect(result == expected)
    }

    @Test("Conversion throws when rate unavailable")
    func testRateUnavailable() async {
        let mock = MockRateProvider()
        mock.shouldFail = true
        let converter = CurrencyConverter(rateProvider: mock)
        do {
            _ = try await converter.convertToTRY(amount: 100, from: .usd)
            #expect(Bool(false), "Expected error")
        } catch {
            #expect(Bool(true))
        }
    }
}

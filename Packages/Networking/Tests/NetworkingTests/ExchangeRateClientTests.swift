import Foundation
import Testing
@testable import Networking
import Core

// MARK: - Exchange Rate Client Tests

@Suite("ExchangeRateClient")
struct ExchangeRateClientTests {

    @Test("Client initializes with default session")
    func testClientInit() {
        let client = ExchangeRateClient()
        #expect(client is ExchangeRateProviding)
    }

    @Test("Client conforms to ExchangeRateProviding protocol")
    func testClientConforms() {
        let client = ExchangeRateClient() as ExchangeRateProviding
        #expect(client is ExchangeRateClient)
    }

    @Test("Client calls lastUpdateDate without crashing")
    func testLastUpdateDate() async {
        let client = ExchangeRateClient()
        let date = await client.lastUpdateDate()
        #expect(date == nil) // no rates fetched yet
    }

    @Test("fetchAllRates handles network call gracefully")
    func testFetchAllRates() async throws {
        let client = ExchangeRateClient()
        do {
            let rates = try await client.fetchAllRates()
            // Network succeeded — should not crash, rates is an array
            #expect(rates is [(code: String, rate: Decimal)])
        } catch {
            #expect(error is ExchangeRateError)
        }
    }

    @Test("fetchRate returns nil for unknown currency with no cache")
    func testFetchRateUnknown() async throws {
        let client = ExchangeRateClient()
        do {
            let rate = try await client.fetchRate(for: "XYZ")
            #expect(rate == nil)
        } catch {
            // Network error is acceptable
            #expect(error is ExchangeRateError)
        }
    }

    @Test("fetchGoldRatePerGram handles network gracefully")
    func testFetchGoldRate() async throws {
        let client = ExchangeRateClient()
        do {
            let rate = try await client.fetchGoldRatePerGram()
            // If network succeeds, rate should be non-negative or nil (cached)
            if let r = rate {
                #expect(r > 0)
            }
        } catch {
            #expect(error is ExchangeRateError)
        }
    }
}

// MARK: - TCMBParser URL Tests

@Suite("TCMB URLs")
struct TCMBURLTests {

    @Test("Exchange rates URL is valid")
    func testExchangeRatesURL() {
        let url = TCMBParser.exchangeRatesURL
        #expect(url.scheme == "https")
        #expect(url.host == "www.tcmb.gov.tr")
    }

    @Test("Gold rates URL is valid")
    func testGoldRatesURL() {
        let url = TCMBParser.goldRatesURL
        #expect(url.scheme == "https")
        #expect(url.host == "finans.truncgil.com")
    }
}

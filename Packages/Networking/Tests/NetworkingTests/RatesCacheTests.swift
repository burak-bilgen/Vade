import Foundation
import Testing
@testable import Networking

@Suite("RatesCache Actor")
struct RatesCacheTests {

    @Test("Cache stores and retrieves rates")
    func testCacheStoreAndRetrieve() async {
        let cache = RatesCache()
        await cache.setRate(Decimal(31.5), for: "USD")

        let rate = await cache.getRate(for: "USD")
        #expect(rate == 31.5)
    }

    @Test("Cache returns nil for missing key")
    func testCacheMissingKey() async {
        let cache = RatesCache()
        let rate = await cache.getRate(for: "EUR")
        #expect(rate == nil)
    }

    @Test("Cache lastUpdateDate is set after storing a rate")
    func testCacheLastUpdateDate() async {
        let cache = RatesCache()
        await cache.setRate(Decimal(31.5), for: "USD")

        let lastUpdate = await cache.lastUpdateDate()
        #expect(lastUpdate != nil)
    }

    @Test("Clear removes all cached data")
    func testCacheClear() async {
        let cache = RatesCache()
        await cache.setRate(Decimal(31.5), for: "USD")
        await cache.clear()

        let rate = await cache.getRate(for: "USD")
        let lastUpdate = await cache.lastUpdateDate()

        #expect(rate == nil)
        #expect(lastUpdate == nil)
    }
}

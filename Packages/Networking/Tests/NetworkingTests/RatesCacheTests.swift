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

    @Test("setRates batches multiple rates at once")
    func testSetRatesBatch() async {
        let cache = RatesCache()
        await cache.setRates(["USD": Decimal(31.5), "EUR": Decimal(35.2)])
        #expect(await cache.getRate(for: "USD") == 31.5)
        #expect(await cache.getRate(for: "EUR") == 35.2)
    }

    @Test("isStale returns true when cache is empty")
    func testIsStaleEmpty() async {
        let cache = RatesCache()
        let stale = await cache.isStale(validityInterval: 3600)
        #expect(stale == true)
    }

    @Test("isStale returns false immediately after store")
    func testIsStaleFresh() async {
        let cache = RatesCache()
        await cache.setRate(Decimal(31.5), for: "USD")
        let stale = await cache.isStale(validityInterval: 3600)
        #expect(stale == false)
    }
}

// MARK: - TCMB XML Parsing Tests

@Suite("TCMB XML Parser")
struct TCMBParserTests {

    @Test("Parses valid TCMB XML with USD and EUR rates")
    func testParseValidXML() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Tarih_Date>
            <Currency CurrencyCode="USD">
                <ForexBuying>31.1234</ForexBuying>
                <ForexSelling>31.1832</ForexSelling>
            </Currency>
            <Currency CurrencyCode="EUR">
                <ForexBuying>35.6789</ForexBuying>
                <ForexSelling>35.7310</ForexSelling>
            </Currency>
        </Tarih_Date>
        """
        let data = Data(xml.utf8)
        let rates = try TCMBParser.parseExchangeRates(from: data)
        #expect(rates["USD"] == 31.1832)
        #expect(rates["EUR"] == 35.7310)
    }

    @Test("Parses TCMB XML with comma decimal separator")
    func testParseCommaDecimal() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Tarih_Date>
            <Currency CurrencyCode="TRY">
                <ForexSelling>1,0000</ForexSelling>
            </Currency>
        </Tarih_Date>
        """
        let data = Data(xml.utf8)
        let rates = try TCMBParser.parseExchangeRates(from: data)
        #expect(rates["TRY"] == 1.0)
    }

    @Test("Parses empty XML returns empty dictionary")
    func testParseEmpty() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Tarih_Date></Tarih_Date>
        """
        let data = Data(xml.utf8)
        let rates = try TCMBParser.parseExchangeRates(from: data)
        #expect(rates.isEmpty)
    }
}

// MARK: - Gold Rate JSON Parsing

@Suite("Gold Rate Parser")
struct GoldRateParserTests {

    @Test("Parses valid gold rate JSON from genelpara.com")
    func testParseGoldRate() throws {
        let json = """
        {"GA": {"alis": "3450.12", "satis": "3455.67"}}
        """
        let data = Data(json.utf8)
        let rate = try TCMBParser.parseGoldRate(from: data)
        #expect(rate == 3455.67)
    }
}

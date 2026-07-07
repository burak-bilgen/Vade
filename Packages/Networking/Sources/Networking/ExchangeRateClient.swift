import Foundation
import Core

// MARK: - Protocols

public protocol ExchangeRateProviding: Sendable {
    func fetchRate(for currency: String) async throws -> Decimal?
    func fetchGoldRatePerGram() async throws -> Decimal?
    func fetchAllRates() async throws -> [(code: String, rate: Decimal)]
    func lastUpdateDate() async -> Date?
}

// MARK: - Rate Cache Actor

public actor RatesCache {
    private var rates: [String: Decimal] = [:]
    private var lastUpdated: Date?

    public init() {}

    public func getRate(for key: String) -> Decimal? { rates[key] }

    public func setRate(_ rate: Decimal, for key: String) {
        rates[key] = rate
        lastUpdated = Date()
    }

    public func setRates(_ newRates: [String: Decimal]) {
        rates.merge(newRates) { _, new in new }
        lastUpdated = Date()
    }

    public func lastUpdateDate() -> Date? { lastUpdated }

    public func isStale(validityInterval: TimeInterval) -> Bool {
        guard let lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) >= validityInterval
    }

    public func clear() {
        rates.removeAll()
        lastUpdated = nil
    }

    public func getAllRates() -> [String: Decimal] { rates }
}

// MARK: - TCMB XML Parser

enum TCMBParser {
    private static let tcmbURL = "https://www.tcmb.gov.tr/kurlar/today.xml"
    private static let goldURL = "https://finans.truncgil.com/v3/today.json"

    /// Parses TCMB daily XML and returns [currencyCode: forexSellingRate]
    static func parseExchangeRates(from xmlData: Data) throws -> [String: Decimal] {
        let parser = TCMBXMLParser()
        parser.parse(xmlData)
        if let error = parser.parserError {
            throw error
        }
        return parser.rates
    }

    /// Parses gold rate from truncgil.com JSON API.
    /// Response format: { "gram-altin": { "Selling": "6.256,89", ... } }
    static func parseGoldRate(from jsonData: Data) throws -> Decimal {
        struct Response: Decodable {
            struct Rate: Decodable { let Selling: String }
            let gramAltin: Rate?
            enum CodingKeys: String, CodingKey {
                case gramAltin = "gram-altin"
            }
        }
        let response = try JSONDecoder().decode(Response.self, from: jsonData)
        guard let rate = response.gramAltin,
              let value = Decimal(string: rate.Selling.replacingOccurrences(of: ",", with: ".")) else {
            throw ExchangeRateError.invalidResponse
        }
        return value
    }

    /// Exchange rates URL — crashes at launch if constant is malformed (caught in testing).
    static let exchangeRatesURL: URL = {
        guard let url = URL(string: tcmbURL) else {
            preconditionFailure("Invalid TCMB URL: \(tcmbURL)")
        }
        return url
    }()
    /// Gold rates URL — crashes at launch if constant is malformed (caught in testing).
    static let goldRatesURL: URL = {
        guard let url = URL(string: goldURL) else {
            preconditionFailure("Invalid gold URL: \(goldURL)")
        }
        return url
    }()
}

// MARK: - TCMB XML Parser (SAX-style via FoundationXML)

private final class TCMBXMLParser: NSObject, XMLParserDelegate {
    var rates: [String: Decimal] = [:]
    var parserError: Error?

    private var currentCurrencyCode: String?
    private var currentElement: String?
    private var currentForexSelling: String?

    func parse(_ data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        currentElement = elementName
        if elementName == "Currency", let code = attributes["CurrencyCode"] {
            currentCurrencyCode = code
            currentForexSelling = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard currentElement == "ForexSelling", let _ = currentCurrencyCode else { return }
        if currentForexSelling == nil {
            currentForexSelling = string.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            currentForexSelling? += string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        if elementName == "Currency",
           let code = currentCurrencyCode,
           let sellingStr = currentForexSelling,
           let rate = Decimal(string: sellingStr.replacingOccurrences(of: ",", with: ".")) {
            rates[code] = rate
        }
        if elementName == "ForexSelling" {
            // already captured in foundCharacters
        }
        currentElement = nil
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parserError = parseError
    }
}

// MARK: - Exchange Rate Client

public final class ExchangeRateClient: ExchangeRateProviding {
    private let cache = RatesCache()
    private let session: URLSession
    private let cacheValidityInterval: TimeInterval = 6 * 3600

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Fetch Rate

    public func fetchRate(for currency: String) async throws -> Decimal? {
        // Return cached rate if fresh
        if let cached = await cache.getRate(for: currency),
           await !cache.isStale(validityInterval: cacheValidityInterval) {
            return cached
        }

        // Fetch fresh rates from TCMB
        return try await fetchAndCacheTCMBRates(for: currency)
    }

    public func fetchGoldRatePerGram() async throws -> Decimal? {
        let key = "GOLD_GRAM"
        if let cached = await cache.getRate(for: key),
           await !cache.isStale(validityInterval: cacheValidityInterval) {
            return cached
        }

        return try await fetchAndCacheGoldRate()
    }

    public func fetchAllRates() async throws -> [(code: String, rate: Decimal)] {
        // Ensure cache is fresh
        if await cache.isStale(validityInterval: cacheValidityInterval) {
            _ = try await fetchAndCacheTCMBRates(for: "USD")
        }
        let allRates = await cache.getAllRates()
        return allRates.map { (code: $0.key, rate: $0.value) }
            .sorted { $0.code < $1.code }
    }

    public func lastUpdateDate() async -> Date? {
        await cache.lastUpdateDate()
    }

    // MARK: - Private

    private func fetchAndCacheTCMBRates(for currency: String) async throws -> Decimal? {
        let (data, response) = try await session.data(from: TCMBParser.exchangeRatesURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ExchangeRateError.invalidResponse
        }

        let parsed = try TCMBParser.parseExchangeRates(from: data)
        await cache.setRates(parsed)
        AppLog.networking.info("[ExchangeRate] Fetched \(parsed.count) rates from TCMB")
        return parsed[currency]
    }

    private func fetchAndCacheGoldRate() async throws -> Decimal? {
        let (data, response) = try await session.data(from: TCMBParser.goldRatesURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ExchangeRateError.invalidResponse
        }

        let rate = try TCMBParser.parseGoldRate(from: data)
        await cache.setRate(rate, for: "GOLD_GRAM")
        AppLog.networking.info("[ExchangeRate] Fetched gold rate: \(rate)")
        return rate
    }
}

// MARK: - Errors

public enum ExchangeRateError: Error, Sendable {
    case invalidResponse
    case parseFailure
    case rateNotFound
}

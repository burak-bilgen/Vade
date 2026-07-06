import Foundation

// MARK: - Protocols

public protocol ExchangeRateProviding: Sendable {
    func fetchTRYEquivalent(for currency: String) async throws -> Decimal?
    func fetchGoldRatePerGram() async throws -> Decimal?
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

    public func lastUpdateDate() -> Date? { lastUpdated }

    public func clear() {
        rates.removeAll()
        lastUpdated = nil
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

    public func fetchTRYEquivalent(for currency: String) async throws -> Decimal? {
        if let lastUpdate = await cache.lastUpdateDate(),
           Date().timeIntervalSince(lastUpdate) < cacheValidityInterval,
           let cached = await cache.getRate(for: currency) {
            return cached
        }
        return nil
    }

    public func fetchGoldRatePerGram() async throws -> Decimal? {
        return nil
    }
}

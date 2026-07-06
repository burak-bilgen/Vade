import Foundation

// MARK: - Currency / Asset Kind

public enum CurrencyKind: String, CaseIterable, Sendable, Codable {
    case tryCoin = "TRY"
    case usd = "USD"
    case eur = "EUR"
    case goldGram = "GRAM_ALTIN"
    case goldCeyrek = "CEYREK"
    case goldYarim = "YARIM"
    case goldTam = "TAM"
    case goldCumhuriyet = "CUMHURIYET"

    /// Maps to the analytics-safe `CurrencyCode` for event tracking.
    /// All gold subtypes collapse into `.gold` — analytics only needs top-level categorization.
    public var analyticsCode: CurrencyCode {
        switch self {
        case .tryCoin: return .tryCoin
        case .usd: return .usd
        case .eur: return .eur
        case .goldGram, .goldCeyrek, .goldYarim, .goldTam, .goldCumhuriyet: return .gold
        }
    }
}

// MARK: - Debt Record Status

public enum DebtStatus: String, Codable, Sendable {
    case pending
    case paid
    case archived
}

// MARK: - Debt Direction

public enum DebtDirection: String, Codable, Sendable {
    case receivable
    case payable
}

// MARK: - Debt Record

public struct DebtRecord: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var personID: UUID
    public var amount: Decimal
    public var kind: CurrencyKind
    public var direction: DebtDirection
    public var note: String?
    public var dueDate: Date?
    public var status: DebtStatus
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        personID: UUID,
        amount: Decimal,
        kind: CurrencyKind = .tryCoin,
        direction: DebtDirection,
        note: String? = nil,
        dueDate: Date? = nil,
        status: DebtStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.personID = personID
        self.amount = amount
        self.kind = kind
        self.direction = direction
        self.note = note
        self.dueDate = dueDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

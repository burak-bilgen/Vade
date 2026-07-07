import Foundation

// MARK: - Decimal Domain Extensions

public extension Decimal {
    /// Rounds to `scale` decimal places using the specified rounding mode.
    func rounded(scale: Int = 2, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var source = self
        var result = Decimal.zero
        NSDecimalRound(&result, &source, scale, mode)
        return result
    }

    public var isEffectivelyZero: Bool { rounded() == 0 }
    public var absoluteValue: Decimal { magnitude }
}

// MARK: - Currency / Asset Kind

public enum CurrencyKind: String, CaseIterable, Sendable, Codable {
    case tryCoin = "TRY"
    case usd = "USD"
    case eur = "EUR"
    case goldGram = "GRAM_ALTIN"
    case goldQuarter = "CEYREK"
    case goldHalf = "YARIM"
    case goldFull = "TAM"
    case goldRepublic = "CUMHURIYET"

    /// Collapses into analytics-safe code. All gold subtypes map to `.gold`.
    public var analyticsCode: CurrencyCode {
        switch self {
        case .tryCoin: return .tryCoin
        case .usd: return .usd
        case .eur: return .eur
        case .goldGram, .goldQuarter, .goldHalf, .goldFull, .goldRepublic: return .gold
        }
    }

    /// Maps to DebtKind for the `debtAdded(kind:)` analytics event.
    public var analyticsDebtKind: DebtKind {
        switch self {
        case .tryCoin: return .cash
        case .usd, .eur: return .foreignCurrency
        case .goldGram, .goldQuarter, .goldHalf, .goldFull, .goldRepublic: return .gold
        }
    }

    /// Display label for gold subtypes. Fiat uses currency symbol (₺, $, €).
    public var label: String {
        switch self {
        case .tryCoin: return "\u{20BA}"
        case .usd: return "$"
        case .eur: return "\u{20AC}"
        case .goldGram: return String(localized: "currency.gold.gram")
        case .goldQuarter: return String(localized: "currency.gold.quarter")
        case .goldHalf: return String(localized: "currency.gold.half")
        case .goldFull: return String(localized: "currency.gold.full")
        case .goldRepublic: return String(localized: "currency.gold.republic")
        }
    }

    /// Whether this is a fiat currency.
    public var isFiat: Bool {
        switch self {
        case .tryCoin, .usd, .eur: return true
        case .goldGram, .goldQuarter, .goldHalf, .goldFull, .goldRepublic: return false
        }
    }

    /// Format amount with currency label: "₺1.500,00" or "5,25 gr"
    public func format(_ amount: Decimal) -> String {
        let number = amount.formatted()
        switch self {
        case .tryCoin, .usd, .eur:
            return "\(label)\(number)"
        case .goldGram, .goldQuarter, .goldHalf, .goldFull, .goldRepublic:
            return "\(number) \(label)"
        }
    }

    /// Gram equivalent for gold subtypes. Fiat currencies return 1.
    /// Values: Quarter=1.75g, Half=3.5g, Full=7g, Republic=7.216g, Gram=1g.
    public var gramEquivalent: Decimal {
        switch self {
        case .goldQuarter: return Decimal(175) / Decimal(100)
        case .goldHalf: return Decimal(35) / Decimal(10)
        case .goldFull: return 7
        case .goldRepublic: return Decimal(7216) / Decimal(1000)
        default: return 1
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

import Foundation
import Domain
import Core
import Networking

// MARK: - Dashboard ViewModel

@MainActor
@Observable
public final class DashboardViewModel {
    public private(set) var persons: [Person] = []
    public private(set) var totalReceivable: Decimal = .zero
    public private(set) var totalPayable: Decimal = .zero
    public private(set) var netBalance: Decimal = .zero
    public private(set) var upcomingItems: [(id: UUID, person: Person, amount: Decimal, kind: CurrencyKind, dueDate: Date?)] = []
    public private(set) var recentActivity: [ActivityItem] = []
    public private(set) var currencyDistribution: [(kind: CurrencyKind, total: Decimal)] = []
    public private(set) var monthlyStats: MonthlyStats = .empty
    public private(set) var exchangeRates: ExchangeRateSnapshot?
    public private(set) var pendingDebts: [DebtRecord] = []

    // MARK: - New Chart Data
    public private(set) var monthlyTrendData: [(month: String, receivable: Decimal, payable: Decimal, net: Decimal)] = []
    public private(set) var pendingDebtCount: Int = 0
    public private(set) var paidDebtCount: Int = 0
    public private(set) var archivedDebtCount: Int = 0
    public private(set) var personBalances: [(name: String, balance: Decimal)] = []
    public private(set) var pendingAmount: Decimal = .zero
    public private(set) var paidAmount: Decimal = .zero
    public private(set) var isLoading = false

    public var upcomingChartItems: [(person: String, amount: Decimal, dueDate: Date)] {
        upcomingItems.compactMap { item in
            guard let date = item.dueDate else { return nil }
            return (item.person.name, item.amount, date)
        }
    }

    private let personRepo: FetchPersonsUseCase
    private let debtRepo: FetchDebtsForPersonUseCase
    private let balanceRepo: CalculateBalanceUseCase
    private let rateClient: ExchangeRateProviding

    public init(
        personRepo: FetchPersonsUseCase,
        debtRepo: FetchDebtsForPersonUseCase,
        balanceRepo: CalculateBalanceUseCase,
        rateClient: ExchangeRateProviding = ExchangeRateClient()
    ) {
        self.personRepo = personRepo
        self.debtRepo = debtRepo
        self.balanceRepo = balanceRepo
        self.rateClient = rateClient
    }

    public func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            persons = try await personRepo.execute(includeArchived: false)
            await refreshBalances()
            await loadUpcoming()
            await loadRecentActivity()
            await loadCurrencyDistribution()
            await loadMonthlyStats()
            await loadExchangeRates()
            await loadChartData()
            await loadPendingDebts()
        } catch {
            AppLog.data.error("[DashboardViewModel] Load failed: \(error.localizedDescription)")
        }
    }

    public func refreshBalances() async {
        var receivable: Decimal = .zero
        var payable: Decimal = .zero

        for person in persons {
            guard let balance = try? await balanceRepo.execute(for: person.id) else { continue }
            if balance > 0 {
                receivable += balance
            } else if balance < 0 {
                payable += balance.magnitude
            }
        }

        totalReceivable = receivable
        totalPayable = payable
        netBalance = receivable - payable

        // Write widget data to shared App Group UserDefaults
        if let defaults = UserDefaults(suiteName: UserDefaultsKeys.appGroupSuite) {
            defaults.set(netBalance.description, forKey: UserDefaultsKeys.widgetNetBalance)
            defaults.set(totalReceivable.description, forKey: UserDefaultsKeys.widgetTotalReceivable)
            defaults.set(totalPayable.description, forKey: UserDefaultsKeys.widgetTotalPayable)
            defaults.set(persons.count, forKey: UserDefaultsKeys.widgetPersonCount)
        }
    }

    private func loadUpcoming() async {
        var items: [(id: UUID, person: Person, amount: Decimal, kind: CurrencyKind, dueDate: Date?)] = []
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            for debt in debts where debt.status == .pending && debt.dueDate != nil {
                items.append((debt.id, person, debt.amount, debt.kind, debt.dueDate))
            }
        }
        upcomingItems = items.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private func loadRecentActivity() async {
        var items: [ActivityItem] = []
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            for debt in debts {
                items.append(ActivityItem(
                    personName: person.name,
                    amount: debt.amount,
                    kind: debt.kind,
                    direction: debt.direction,
                    date: debt.createdAt,
                    note: debt.note
                ))
            }
        }
        recentActivity = items.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }

    private func loadCurrencyDistribution() async {
        var dist: [CurrencyKind: Decimal] = [:]
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            for debt in debts where debt.status == .pending {
                dist[debt.kind, default: .zero] += debt.amount
            }
        }
        currencyDistribution = dist.map { ($0.key, $0.value) }
            .sorted { $0.total > $1.total }
    }

    private func loadPendingDebts() async {
        var allPending: [DebtRecord] = []
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            allPending.append(contentsOf: debts.filter { $0.status == .pending })
        }
        pendingDebts = allPending
    }

    private func loadExchangeRates() async {
        async let usdRate = try? await rateClient.fetchRate(for: "USD")
        async let eurRate = try? await rateClient.fetchRate(for: "EUR")
        async let gbpRate = try? await rateClient.fetchRate(for: "GBP")
        async let chfRate = try? await rateClient.fetchRate(for: "CHF")
        async let jpyRate = try? await rateClient.fetchRate(for: "JPY")
        async let goldRate = try? await rateClient.fetchGoldRatePerGram()
        let lastUpdate = await rateClient.lastUpdateDate()

        let (usd, eur, gbp, chf, jpy, gold) = await (usdRate, eurRate, gbpRate, chfRate, jpyRate, goldRate)
        if usd != nil || eur != nil || gold != nil {
            exchangeRates = ExchangeRateSnapshot(
                usdRate: usd,
                eurRate: eur,
                goldRate: gold,
                gbpRate: gbp,
                chfRate: chf,
                jpyRate: jpy,
                lastUpdate: lastUpdate
            )
        }
    }

    private func loadMonthlyStats() async {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return }

        var activeCount = 0
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            let monthDebts = debts.filter { $0.createdAt >= monthStart }
            if !monthDebts.isEmpty { activeCount += 1 }
        }

        monthlyStats = MonthlyStats(
            activePersonCount: activeCount,
            totalPersonCount: persons.count,
            pendingDebtCount: upcomingItems.count
        )
    }

    // MARK: - Chart Data Loading

    private func loadChartData() async {
        // Monthly trend: aggregate by month for last 6 months
        let calendar = Calendar.current
        let now = Date()
        var trendData: [(month: String, receivable: Decimal, payable: Decimal, net: Decimal)] = []

        for monthOffset in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
            let monthComponents = calendar.dateComponents([.year, .month], from: monthDate)
            guard let monthStart = calendar.date(from: monthComponents),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }

            var monthReceivable: Decimal = 0
            var monthPayable: Decimal = 0

            for person in persons {
                guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
                let monthDebts = debts.filter { $0.createdAt >= monthStart && $0.createdAt < monthEnd }
                for debt in monthDebts {
                    if debt.direction == .receivable {
                        monthReceivable += debt.amount
                    } else {
                        monthPayable += debt.amount
                    }
                }
            }

            let monthLabel: String = {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return formatter.string(from: monthStart)
            }()

            trendData.append((monthLabel, monthReceivable, monthPayable, monthReceivable - monthPayable))
        }

        monthlyTrendData = trendData

        // Status distribution counts & amounts
        var pending = 0
        var paid = 0
        var archived = 0
        var pendingTotal: Decimal = 0
        var paidTotal: Decimal = 0
        var balanceList: [(name: String, balance: Decimal)] = []
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            var personBalance: Decimal = 0
            for debt in debts {
                switch debt.status {
                case .pending: pending += 1
                case .paid: paid += 1
                case .archived: archived += 1
                }
                if debt.direction == .receivable {
                    if debt.status == .pending { pendingTotal += debt.amount }
                    if debt.status == .paid { paidTotal += debt.amount }
                    personBalance += debt.amount
                } else {
                    if debt.status == .pending { pendingTotal += debt.amount }
                    if debt.status == .paid { paidTotal += debt.amount }
                    personBalance -= debt.amount
                }
            }
            if personBalance != 0 || !balanceList.isEmpty {
                balanceList.append((person.name, personBalance))
            }
        }
        pendingDebtCount = pending
        paidDebtCount = paid
        archivedDebtCount = archived
        pendingAmount = pendingTotal
        paidAmount = paidTotal
        personBalances = balanceList.sorted { abs($0.balance) > abs($1.balance) }
    }

    public var financialHealthScore: Int {
        var score = 100
        
        let now = Date()
        let overdueCount = upcomingItems.filter { $0.dueDate != nil && $0.dueDate! < now }.count
        score -= (overdueCount * 15)
        
        if totalReceivable > 0 {
            let ratio = Double(truncating: (totalPayable / totalReceivable) as NSNumber)
            if ratio > 1.5 {
                score -= 15
            } else if ratio > 1.0 {
                score -= 10
            }
        } else if totalPayable > 0 {
            score -= 20
        }
        
        return max(30, min(100, score))
    }
    
    public var healthDetails: HealthDetails {
        let score = financialHealthScore
        let status: HealthStatus
        let titleKey: String
        let descKey: String
        let recKey: String
        
        let now = Date()
        let overdueCount = upcomingItems.filter { $0.dueDate != nil && $0.dueDate! < now }.count
        
        if score >= 90 {
            status = .excellent
            titleKey = "health.excellent.title"
            descKey = "health.desc"
            recKey = "health.excellent.desc"
        } else if score >= 70 {
            status = .good
            titleKey = "health.good.title"
            descKey = "health.desc"
            recKey = overdueCount > 0 ? "health.good.overdue.desc" : "health.good.desc"
        } else if score >= 50 {
            status = .warning
            titleKey = "health.warning.title"
            descKey = "health.desc"
            recKey = overdueCount > 0 ? "health.warning.overdue.desc" : "health.warning.desc"
        } else {
            status = .critical
            titleKey = "health.critical.title"
            descKey = "health.desc"
            recKey = "health.critical.desc"
        }
        
        return HealthDetails(score: score, status: status, titleKey: titleKey, descKey: descKey, recommendationKey: recKey)
    }
}

// MARK: - Supporting Types

public enum HealthStatus: String, Sendable {
    case excellent
    case good
    case warning
    case critical
}

public struct HealthDetails: Sendable {
    public let score: Int
    public let status: HealthStatus
    public let titleKey: String
    public let descKey: String
    public let recommendationKey: String
}

// MARK: - Supporting Types

public struct ActivityItem: Identifiable, Sendable {
    public let id = UUID()
    public let personName: String
    public let amount: Decimal
    public let kind: CurrencyKind
    public let direction: DebtDirection
    public let date: Date
    public let note: String?
}

public struct MonthlyStats: Sendable {
    public let activePersonCount: Int
    public let totalPersonCount: Int
    public let pendingDebtCount: Int

    public static let empty = MonthlyStats(activePersonCount: 0, totalPersonCount: 0, pendingDebtCount: 0)
}

public struct ExchangeRateSnapshot: Sendable {
    public let usdRate: Decimal?
    public let eurRate: Decimal?
    public let goldRate: Decimal?
    public let gbpRate: Decimal?
    public let chfRate: Decimal?
    public let jpyRate: Decimal?
    public let lastUpdate: Date?

    public init(
        usdRate: Decimal? = nil,
        eurRate: Decimal? = nil,
        goldRate: Decimal? = nil,
        gbpRate: Decimal? = nil,
        chfRate: Decimal? = nil,
        jpyRate: Decimal? = nil,
        lastUpdate: Date? = nil
    ) {
        self.usdRate = usdRate
        self.eurRate = eurRate
        self.goldRate = goldRate
        self.gbpRate = gbpRate
        self.chfRate = chfRate
        self.jpyRate = jpyRate
        self.lastUpdate = lastUpdate
    }
}

import Foundation
import Domain
import Core
import Networking

// MARK: - Dashboard ViewModel

@MainActor
@Observable
public final class DashboardViewModel {
    public var persons: [Person] = []
    public var totalReceivable: Decimal = .zero
    public var totalPayable: Decimal = .zero
    public var netBalance: Decimal = .zero
    public var upcomingItems: [(id: UUID, person: Person, amount: Decimal, dueDate: Date?)] = []
    public var recentActivity: [ActivityItem] = []
    public var currencyDistribution: [(kind: CurrencyKind, total: Decimal)] = []
    public var monthlyStats: MonthlyStats = .empty
    public var exchangeRates: ExchangeRateSnapshot?

    // MARK: - New Chart Data
    public var monthlyTrendData: [(month: String, receivable: Decimal, payable: Decimal, net: Decimal)] = []
    public var pendingDebtCount: Int = 0
    public var paidDebtCount: Int = 0
    public var archivedDebtCount: Int = 0
    public var isLoading = false

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
            // Step 1: Fetch persons first (needed by all other loads)
            persons = try await personRepo.execute(includeArchived: false)

            // Step 2: Fire all dependent loads in parallel
            async let balances = refreshBalances()
            async let upcoming = loadUpcoming()
            async let activity = loadRecentActivity()
            async let currencyDist = loadCurrencyDistribution()
            async let stats = loadMonthlyStats()
            async let rates = loadExchangeRates()
            async let chartData = loadChartData()

            let (_, _, _, _, _, _, _) = await (balances, upcoming, activity, currencyDist, stats, rates, chartData)
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
        var items: [(id: UUID, person: Person, amount: Decimal, dueDate: Date?)] = []
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            for debt in debts where debt.status == .pending && debt.dueDate != nil {
                items.append((debt.id, person, debt.amount, debt.dueDate))
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

    private func loadExchangeRates() async {
        async let usdRate = try? await rateClient.fetchRate(for: "USD")
        async let eurRate = try? await rateClient.fetchRate(for: "EUR")
        async let goldRate = try? await rateClient.fetchGoldRatePerGram()
        let lastUpdate = await rateClient.lastUpdateDate()

        let (usd, eur, gold) = await (usdRate, eurRate, goldRate)
        if usd != nil || eur != nil || gold != nil {
            exchangeRates = ExchangeRateSnapshot(
                usdRate: usd,
                eurRate: eur,
                goldRate: gold,
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

        // Status distribution counts
        var pending = 0
        var paid = 0
        var archived = 0
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            for debt in debts {
                switch debt.status {
                case .pending: pending += 1
                case .paid: paid += 1
                case .archived: archived += 1
                }
            }
        }
        pendingDebtCount = pending
        paidDebtCount = paid
        archivedDebtCount = archived
    }
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
    public let lastUpdate: Date?
}

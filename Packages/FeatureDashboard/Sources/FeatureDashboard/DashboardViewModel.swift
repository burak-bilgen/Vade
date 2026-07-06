import Foundation
import SwiftData
import Domain
import Core
import Data

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
    public var isLoading = false

    private let personRepo: PersonRepository
    private let debtRepo: DebtRepository
    private let balanceRepo: BalanceRepository

    public init(modelContext: ModelContext) {
        self.personRepo = PersonRepository(modelContext: modelContext)
        self.debtRepo = DebtRepository(modelContext: modelContext)
        self.balanceRepo = BalanceRepository(modelContext: modelContext)
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

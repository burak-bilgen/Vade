import Foundation
import SwiftData
import Domain

// MARK: - Dashboard ViewModel

@MainActor
@Observable
public final class DashboardViewModel {
    public var persons: [Person] = []
    public var totalReceivable: Decimal = .zero
    public var totalPayable: Decimal = .zero
    public var netBalance: Decimal = .zero
    public var upcomingItems: [(person: Person, amount: Decimal, dueDate: Date?)] = []
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
    }

    private func loadUpcoming() async {
        var items: [(person: Person, amount: Decimal, dueDate: Date?)] = []
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            for debt in debts where debt.status == .pending && debt.dueDate != nil {
                items.append((person, debt.amount, debt.dueDate))
            }
        }
        upcomingItems = items.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
}

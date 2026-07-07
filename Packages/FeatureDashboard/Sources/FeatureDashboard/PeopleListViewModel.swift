import Foundation
import Domain
import Core
import Observability

// MARK: - Status Filter

public enum DebtStatusFilter: String, CaseIterable, Sendable {
    case all
    case pending
    case paid
}

// MARK: - People List ViewModel

@MainActor
@Observable
public final class PeopleListViewModel {
    public var persons: [Person] = []
    public var personBalances: [UUID: Decimal] = [:]
    public var selectedSegment: PeopleSegment = .receivable
    public var selectedStatusFilter: DebtStatusFilter = .all
    public var isLoading = false
    /// Maps person ID to the set of debt statuses they have.
    public private(set) var personDebtStatuses: [UUID: Set<DebtStatus>] = [:]

    private let personRepo: AddPersonUseCase & FetchPersonsUseCase
    private let balanceRepo: CalculateBalanceUseCase
    private let debtRepo: FetchDebtsForPersonUseCase
    private let analytics: any AnalyticsTracking

    public init(
        personRepo: AddPersonUseCase & FetchPersonsUseCase,
        balanceRepo: CalculateBalanceUseCase,
        debtRepo: FetchDebtsForPersonUseCase,
        analytics: any AnalyticsTracking = AnalyticsService()
    ) {
        self.personRepo = personRepo
        self.balanceRepo = balanceRepo
        self.debtRepo = debtRepo
        self.analytics = analytics
    }

    public var filteredPersons: [(person: Person, balance: Decimal)] {
        let segmentFiltered = persons.compactMap { person -> (Person, Decimal)? in
            guard let balance = personBalances[person.id] else { return nil }
            switch selectedSegment {
            case .receivable where balance > 0:
                return (person, balance)
            case .payable where balance < 0:
                return (person, balance.magnitude)
            default:
                return nil
            }
        }

        switch selectedStatusFilter {
        case .all:
            return segmentFiltered
        case .pending:
            return segmentFiltered.filter { person, _ in
                personDebtStatuses[person.id]?.contains(.pending) == true
            }
        case .paid:
            return segmentFiltered.filter { person, _ in
                personDebtStatuses[person.id]?.contains(.paid) == true
            }
        }
    }

    public func loadPersons() async {
        isLoading = true
        defer { isLoading = false }
        do {
            persons = try await personRepo.execute(includeArchived: false)
            // Pre-compute all balances in parallel
            var balances: [UUID: Decimal] = [:]
            var statuses: [UUID: Set<DebtStatus>] = [:]
            for person in persons {
                balances[person.id] = try await balanceRepo.execute(for: person.id)
                let debts = try await debtRepo.execute(for: person.id)
                statuses[person.id] = Set(debts.map(\.status))
            }
            personBalances = balances
            personDebtStatuses = statuses
        } catch {
            AppLog.data.error("[PeopleListViewModel] Failed to load: \(error.localizedDescription)")
        }
    }

    public func addPerson(name: String, phoneNumber: String?, notes: String?) async {
        do {
            _ = try await personRepo.execute(name: name, phoneNumber: phoneNumber, notes: notes)
            analytics.track(.personAdded)
            await loadPersons()
        } catch {
            AppLog.data.error("[PeopleListViewModel] Add person failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Segment

public enum PeopleSegment: String, CaseIterable, Sendable {
    case receivable
    case payable
}

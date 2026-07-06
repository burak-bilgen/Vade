import Foundation
import SwiftData
import Domain

// MARK: - People List ViewModel

@MainActor
@Observable
public final class PeopleListViewModel {
    public var persons: [Person] = []
    public var personBalances: [UUID: Decimal] = [:]
    public var selectedSegment: PeopleSegment = .receivable
    public var isLoading = false

    private let personRepo: PersonRepository
    private let balanceRepo: BalanceRepository

    public init(modelContext: ModelContext) {
        self.personRepo = PersonRepository(modelContext: modelContext)
        self.balanceRepo = BalanceRepository(modelContext: modelContext)
    }

    public var filteredPersons: [(person: Person, balance: Decimal)] {
        persons.compactMap { person in
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
    }

    public func loadPersons() async {
        isLoading = true
        defer { isLoading = false }
        do {
            persons = try await personRepo.execute(includeArchived: false)
            // Pre-compute all balances in parallel
            var balances: [UUID: Decimal] = [:]
            for person in persons {
                balances[person.id] = try await balanceRepo.execute(for: person.id)
            }
            personBalances = balances
        } catch {
            AppLog.data.error("[PeopleListViewModel] Failed to load: \(error.localizedDescription)")
        }
    }

    public func addPerson(name: String, phoneNumber: String?, notes: String?) async {
        do {
            _ = try await personRepo.execute(name: name, phoneNumber: phoneNumber, notes: notes)
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

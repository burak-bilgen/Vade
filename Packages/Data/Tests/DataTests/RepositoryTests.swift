import Foundation
import Testing
import SwiftData
import Domain
@testable import Data

@Suite("Repository implementations Tests")
struct RepositoryTests {
    
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            PersonModel.self,
            DebtRecordModel.self,
            PaymentModel.self,
            AuditEntryModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
    
    // MARK: - PersonRepository Tests
    
    @Test("PersonRepository basic CRUD operations")
    @MainActor
    func testPersonRepositoryCRUD() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let repo = PersonRepository(modelContext: context)
        
        // 1. Create (insert)
        let person = try await repo.execute(name: "Ali Veli", phoneNumber: "+905001112233", notes: "Test note")
        #expect(person.name == "Ali Veli")
        #expect(person.phoneNumber == "+905001112233")
        #expect(person.notes == "Test note")
        
        // Fetch to verify insertion
        let listAfterInsert = try await repo.execute(includeArchived: false)
        #expect(listAfterInsert.count == 1)
        #expect(listAfterInsert[0].id == person.id)
        
        // 2. Update
        let updatedPerson = try await repo.execute(personID: person.id, name: "Ali Veli Güncel", phoneNumber: "+905001112244", notes: "Güncel Test Note")
        #expect(updatedPerson.name == "Ali Veli Güncel")
        #expect(updatedPerson.phoneNumber == "+905001112244")
        #expect(updatedPerson.notes == "Güncel Test Note")
        
        // Try update with invalid ID should throw notFound
        let randomID = UUID()
        await #expect(throws: RepositoryError.notFound) {
            _ = try await repo.execute(personID: randomID, name: "Non-existent", phoneNumber: nil, notes: nil)
        }
        
        // 3. Delete
        try await repo.execute(personID: person.id)
        let listAfterDelete = try await repo.execute(includeArchived: false)
        #expect(listAfterDelete.isEmpty)
        
        // Try delete with invalid ID should throw notFound
        await #expect(throws: RepositoryError.notFound) {
            try await repo.execute(personID: randomID)
        }
    }
    
    // MARK: - DebtRepository Tests
    
    @Test("DebtRepository basic CRUD operations")
    @MainActor
    func testDebtRepositoryCRUD() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let auditService = AuditTrailService(modelContainer: container)
        let repo = DebtRepository(modelContext: context, auditTrail: auditService)
        
        let personID = UUID()
        
        // 1. Create debt
        let now = Date()
        let record = try await repo.execute(
            personID: personID,
            amount: 150.50,
            kind: .usd,
            direction: .receivable,
            note: "Dolar borcu",
            dueDate: now
        )
        #expect(record.amount == 150.50)
        #expect(record.kind == .usd)
        #expect(record.direction == .receivable)
        #expect(record.note == "Dolar borcu")
        #expect(record.dueDate == now)
        
        // 2. Fetch list & single
        let fetchedList = try await repo.execute(for: personID)
        #expect(fetchedList.count == 1)
        #expect(fetchedList[0].id == record.id)
        
        let fetchedSingle: DebtRecord? = try await repo.execute(debtID: record.id)
        #expect(fetchedSingle?.id == record.id)
        
        // Fetch non-existent single should return nil
        let nonExistentSingle: DebtRecord? = try await repo.execute(debtID: UUID())
        #expect(nonExistentSingle == nil)
        
        // 3. Update debt
        let updatedRecord = try await repo.execute(
            debtID: record.id,
            amount: 200.0,
            kind: .eur,
            direction: .payable,
            note: "Euro borcu güncel",
            dueDate: now
        )
        #expect(updatedRecord.amount == 200.0)
        #expect(updatedRecord.kind == .eur)
        #expect(updatedRecord.direction == .payable)
        #expect(updatedRecord.note == "Euro borcu güncel")
        
        // Try update with invalid ID should throw notFound
        await #expect(throws: RepositoryError.notFound) {
            _ = try await repo.execute(
                debtID: UUID(),
                amount: 10,
                kind: .tryCoin,
                direction: .receivable,
                note: nil,
                dueDate: nil
            )
        }
        
        // 4. Delete debt
        try await (repo as DeleteDebtUseCase).execute(debtID: record.id)
        let fetchedListAfterDelete = try await repo.execute(for: personID)
        #expect(fetchedListAfterDelete.isEmpty)
        
        // Try delete with invalid ID should throw notFound
        await #expect(throws: RepositoryError.notFound) {
            try await (repo as DeleteDebtUseCase).execute(debtID: UUID())
        }
    }
    
    // MARK: - PaymentRepository Tests
    
    @Test("PaymentRepository operations")
    @MainActor
    func testPaymentRepository() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let auditService = AuditTrailService(modelContainer: container)
        let paymentRepo = PaymentRepository(modelContext: context, auditTrail: auditService)
        
        let personID = UUID()
        let debtRecord = DebtRecordModel(
            personID: personID,
            amount: 500,
            kindRawValue: "TRY",
            directionRawValue: "receivable",
            statusRawValue: "pending"
        )
        context.insert(debtRecord)
        try context.save()
        
        // 1. Record payment
        let payment = try await paymentRepo.execute(debtRecordID: debtRecord.id, amount: 250, note: "Yarım ödeme")
        #expect(payment.amount == 250)
        #expect(payment.note == "Yarım ödeme")
        #expect(payment.debtRecordID == debtRecord.id)
        
        // Verify relationship
        #expect(debtRecord.payments.count == 1)
        #expect(debtRecord.payments.first?.amount == 250)
        
        // 2. Fetch payments for debt
        let list = try await paymentRepo.execute(for: debtRecord.id)
        #expect(list.count == 1)
        #expect(list[0].id == payment.id)
    }
    
    // MARK: - AuditTrailService Tests
    
    @Test("AuditTrailService writes entries properly")
    @MainActor
    func testAuditTrailService() async throws {
        let container = try createTestContainer()
        let auditService = AuditTrailService(modelContainer: container)
        
        let debtID = UUID()
        
        // Record sync conflict
        await auditService.recordSyncConflict(debtRecordID: debtID, localValue: "A", remoteValue: "B")
        
        // Retrieve and check
        let context = container.mainContext
        let entries = try context.fetch(FetchDescriptor<AuditEntryModel>())
        #expect(entries.count == 1)
        #expect(entries[0].debtRecordID == debtID)
        #expect(entries[0].oldValue == "A")
        #expect(entries[0].newValue == "B")
        #expect(entries[0].reasonRawValue == AuditReason.cloudKitConflict.rawValue)
    }
}

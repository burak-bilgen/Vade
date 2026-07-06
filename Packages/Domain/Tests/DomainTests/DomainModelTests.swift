import Foundation
import Testing
import Domain

@Suite("Domain Models")
struct DomainModelTests {

    @Test("Person initializes with default values")
    func testPersonDefaultInit() {
        let person = Person(name: "Ahmet")
        #expect(person.name == "Ahmet")
        #expect(person.isArchived == false)
        #expect(person.phoneNumber == nil)
    }

    @Test("DebtRecord initializes with correct direction")
    func testDebtRecordDirection() {
        let record = DebtRecord(
            personID: UUID(),
            amount: 1500,
            kind: .tryCoin,
            direction: .receivable
        )
        #expect(record.direction == .receivable)
        #expect(record.status == .pending)
        #expect(record.amount == 1500)
    }

    @Test("Payment initializes with required fields")
    func testPaymentInit() {
        let payment = Payment(debtRecordID: UUID(), amount: 500)
        #expect(payment.amount == 500)
        #expect(payment.note == nil)
    }
}

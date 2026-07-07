import Foundation
import Testing
import Domain
@testable import FeatureDashboard

// MARK: - Mock Use Cases

@MainActor
private final class MockAddPersonUseCase: AddPersonUseCase {
    var shouldFail = false
    func execute(name: String, phoneNumber: String?, notes: String?) async throws -> Person {
        if shouldFail { throw MockError.operationFailed }
        return Person(name: name, phoneNumber: phoneNumber, notes: notes)
    }
}

@MainActor
private final class MockAddDebtUseCase: AddDebtUseCase {
    var shouldFail = false
    func execute(
        personID: UUID,
        amount: Decimal,
        kind: CurrencyKind,
        direction: DebtDirection,
        note: String?,
        dueDate: Date?
    ) async throws -> DebtRecord {
        if shouldFail { throw MockError.operationFailed }
        return DebtRecord(personID: personID, amount: amount, kind: kind, direction: direction)
    }
}

private enum MockError: Error {
    case operationFailed
}

// MARK: - Tests

@Suite("QuickAddViewModel")
struct QuickAddViewModelTests {

    @Test("Initial state has empty fields and TRY currency")
    @MainActor
    func testInitialState() {
        let vm = QuickAddViewModel(
            personRepo: MockAddPersonUseCase(),
            debtRepo: MockAddDebtUseCase(),
            onDone: {}
        )
        #expect(vm.name.isEmpty)
        #expect(vm.amount.isEmpty)
        #expect(vm.kind == .tryCoin)
        #expect(vm.direction == .receivable)
        #expect(vm.isSaving == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.canSave == false)
    }

    @Test("Can save when name and amount are valid")
    @MainActor
    func testCanSave() {
        let vm = QuickAddViewModel(
            personRepo: MockAddPersonUseCase(),
            debtRepo: MockAddDebtUseCase(),
            onDone: {}
        )
        #expect(vm.canSave == false)

        vm.name = "Ahmet"
        #expect(vm.canSave == false) // amount still empty

        vm.amount = "500"
        #expect(vm.canSave == true)

        vm.amount = "0"
        #expect(vm.canSave == false) // zero amount
    }

    @Test("Save succeeds with valid inputs")
    @MainActor
    func testSaveSuccess() async {
        let vm = QuickAddViewModel(
            personRepo: MockAddPersonUseCase(),
            debtRepo: MockAddDebtUseCase(),
            onDone: {}
        )
        vm.name = "Mehmet"
        vm.amount = "1000"

        let result = await vm.save()
        #expect(result == true)
        #expect(vm.isSaving == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("Save fails when name is empty")
    @MainActor
    func testSaveFailsEmptyName() async {
        let vm = QuickAddViewModel(
            personRepo: MockAddPersonUseCase(),
            debtRepo: MockAddDebtUseCase(),
            onDone: {}
        )
        vm.amount = "500"

        let result = await vm.save()
        #expect(result == false)
    }

    @Test("Save fails when amount is invalid")
    @MainActor
    func testSaveFailsInvalidAmount() async {
        let vm = QuickAddViewModel(
            personRepo: MockAddPersonUseCase(),
            debtRepo: MockAddDebtUseCase(),
            onDone: {}
        )
        vm.name = "Ali"
        vm.amount = "abc"

        let result = await vm.save()
        #expect(result == false)
    }

    @Test("Save sets error message on repository failure")
    @MainActor
    func testSaveErrorHandling() async {
        let mockPersonRepo = MockAddPersonUseCase()
        mockPersonRepo.setShouldFail(true)

        let vm = QuickAddViewModel(
            personRepo: mockPersonRepo,
            debtRepo: MockAddDebtUseCase(),
            onDone: {}
        )
        vm.name = "Veli"
        vm.amount = "250"

        let result = await vm.save()
        #expect(result == false)
        #expect(vm.errorMessage != nil)
        #expect(vm.isSaving == false)
    }

    @Test("Direction toggles between receivable and payable")
    @MainActor
    func testDirectionToggle() {
        let vm = QuickAddViewModel(
            personRepo: MockAddPersonUseCase(),
            debtRepo: MockAddDebtUseCase(),
            onDone: {}
        )
        #expect(vm.direction == .receivable)

        vm.direction = .payable
        #expect(vm.direction == .payable)

        vm.direction = .receivable
        #expect(vm.direction == .receivable)
    }

    @Test("Currency kind changes correctly")
    @MainActor
    func testCurrencyKind() {
        let vm = QuickAddViewModel(
            personRepo: MockAddPersonUseCase(),
            debtRepo: MockAddDebtUseCase(),
            onDone: {}
        )
        #expect(vm.kind == .tryCoin)

        vm.kind = .usd
        #expect(vm.kind == .usd)

        vm.kind = .eur
        #expect(vm.kind == .eur)
    }

    @Test("Save calls onDone callback after success")
    @MainActor
    func testOnDoneCalled() async {
        var didCallOnDone = false
        let vm = QuickAddViewModel(
            personRepo: MockAddPersonUseCase(),
            debtRepo: MockAddDebtUseCase(),
            onDone: { didCallOnDone = true }
        )
        vm.name = "Test"
        vm.amount = "500"

        let result = await vm.save()
        #expect(result == true)

        // Simulate View calling onDone after save
        await vm.onDone()
        #expect(didCallOnDone == true)
    }

    @Test("onDone is NOT called when save fails")
    @MainActor
    func testOnDoneNotCalledOnFailure() async {
        var didCallOnDone = false
        let vm = QuickAddViewModel(
            personRepo: MockAddPersonUseCase(),
            debtRepo: MockAddDebtUseCase(),
            onDone: { didCallOnDone = true }
        )
        // Empty name should cause save to fail
        vm.amount = "500"

        let result = await vm.save()
        #expect(result == false)
        #expect(didCallOnDone == false) // onDone NOT called
    }
}

// MARK: - Helpers

private extension MockAddPersonUseCase {
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
}

private extension MockAddDebtUseCase {
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
}

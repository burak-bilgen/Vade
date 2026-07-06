import Testing
@testable import DIContainer

// MARK: - Test Protocols

private protocol TestService: AnyObject {
    func doSomething() -> String
}

private final class MockTestService: TestService {
    func doSomething() -> String { "mock" }
}

// MARK: - Tests

@Suite("DI Container")
struct DIContainerTests {

    @Test("Container resolves a registered singleton service")
    func testResolveSingleton() {
        let container = Container()
        container.register(TestService.self, scope: .singleton) { _ in
            MockTestService()
        }

        let resolved: TestService? = container.resolve(TestService.self)
        #expect(resolved != nil)
        #expect(resolved?.doSomething() == "mock")
    }

    @Test("Container returns nil for unregistered service")
    func testResolveUnregistered() {
        let container = Container()
        let resolved: TestService? = container.resolve(TestService.self)
        #expect(resolved == nil)
    }

    @Test("Singleton scope returns the same instance")
    func testSingletonReturnsSameInstance() {
        let container = Container()
        let expected = MockTestService()
        container.registerInstance(TestService.self, instance: expected)

        let first: TestService? = container.resolve(TestService.self)
        let second: TestService? = container.resolve(TestService.self)
        #expect(first === second)
    }

    @Test("Transient scope returns new instances")
    func testTransientReturnsNewInstances() {
        let container = Container()
        container.register(TestService.self, scope: .transient) { _ in
            MockTestService()
        }

        let first: TestService? = container.resolve(TestService.self)
        let second: TestService? = container.resolve(TestService.self)
        #expect(first !== second)
    }
}

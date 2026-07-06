import Foundation
import Testing
@testable import Core

@Suite("Keychain Wrapper")
struct KeychainWrapperTests {
    private let testKey = "com.vade.test.\(UUID().uuidString)"

    @Test("Save and read data round-trips correctly")
    func testSaveAndRead() throws {
        let keychain = KeychainWrapper()
        let data = "test-secret".data(using: .utf8)!
        try keychain.save(data, forKey: testKey)
        let read = try keychain.read(key: testKey)
        #expect(read == data)
        try keychain.delete(key: testKey)
    }

    @Test("Read returns nil for non-existent key")
    func testReadNonexistent() throws {
        let keychain = KeychainWrapper()
        let result = try keychain.read(key: "nonexistent.\(UUID().uuidString)")
        #expect(result == nil)
    }

    @Test("Delete removes stored data")
    func testDelete() throws {
        let keychain = KeychainWrapper()
        let key = "delete.\(UUID().uuidString)"
        try keychain.save(Data("x".utf8), forKey: key)
        try keychain.delete(key: key)
        #expect(try keychain.read(key: key) == nil)
    }

    @Test("Delete non-existent key does not throw")
    func testDeleteNonexistent() throws {
        let keychain = KeychainWrapper()
        try keychain.delete(key: "nonexistent.\(UUID().uuidString)")
        #expect(Bool(true))
    }
}

@Suite("Jailbreak Detector")
struct JailbreakDetectorTests {

    @Test("Simulator is never reported as jailbroken")
    func testSimulatorNotJailbroken() {
        #if targetEnvironment(simulator)
        #expect(JailbreakDetector.isJailbroken == false)
        #else
        // On device: test is informational only
        _ = JailbreakDetector.isJailbroken
        #expect(Bool(true))
        #endif
    }
}

@Suite("Biometric Auth Service")
struct BiometricAuthServiceTests {

    @Test("Service initializes without crashing")
    func testInit() {
        let service = BiometricAuthService()
        #expect(Bool(true))
    }

    @Test("Biometry type label returns non-empty string")
    func testLabel() {
        let service = BiometricAuthService()
        let label = service.biometryTypeLabel
        #expect(!label.isEmpty)
    }
}

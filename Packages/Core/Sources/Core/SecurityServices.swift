import Foundation
import LocalAuthentication
import OSLog

// MARK: - Biometric Authentication Protocol

public protocol BiometricAuthProviding: Sendable {
    var isBiometryAvailable: Bool { get }
    var biometryTypeLabel: String { get }
    func authenticate(reason: String) async throws -> Bool
}

// MARK: - Biometric Authentication Service

public final class BiometricAuthService: BiometricAuthProviding, @unchecked Sendable {
    private let contextProvider: @Sendable () -> LAContext
    private let logger = Logger(subsystem: "com.vade.core", category: "biometry")

    public init(contextProvider: @escaping @Sendable () -> LAContext = { LAContext() }) {
        self.contextProvider = contextProvider
    }

    public var isBiometryAvailable: Bool {
        let context = contextProvider()
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        if let error {
            logger.info("[Biometry] Not available: \(error.localizedDescription)")
        }
        return available
    }

    public var biometryTypeLabel: String {
        let context = contextProvider()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID: return String(localized: "biometry.faceID")
        case .touchID: return String(localized: "biometry.touchID")
        case .opticID: return String(localized: "biometry.opticID")
        default: return String(localized: "biometry.passcode")
        }
    }

    public func authenticate(reason: String) async throws -> Bool {
        let context = contextProvider()
        guard isBiometryAvailable else { return false }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        )
    }
}

// MARK: - Keychain Wrapper

public protocol KeychainProviding: Sendable {
    func save(_ data: Data, forKey key: String) throws
    func read(key: String) throws -> Data?
    func delete(key: String) throws
}

public final class KeychainWrapper: KeychainProviding {
    private let service: String

    public init(service: String? = nil) {
        if let service {
            self.service = service
        } else if let bundleID = Bundle.main.bundleIdentifier {
            self.service = bundleID + ".keychain"
        } else {
            self.service = "com.vade.keychain"
        }
    }

    public func save(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    public func read(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.readFailed(status)
        }
        return result as? Data
    }

    public func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

public enum KeychainError: Error, Sendable {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
}

// MARK: - Jailbreak Detection (Passive)

public enum JailbreakDetector {
    private static let logger = Logger(subsystem: "com.vade.core", category: "security")

    /// Passive jailbreak detection — does NOT block the app.
    /// Returns true if common jailbreak indicators are found.
    public static var isJailbroken: Bool {
        #if targetEnvironment(simulator)
            return false
        #else
            // Only check for Cydia and MobileSubstrate — the most reliable jailbreak indicators.
            // /bin/bash, /usr/sbin/sshd exist on stock iOS rootfs and cause false positives.
            let paths = [
                "/Applications/Cydia.app",
                "/Library/MobileSubstrate/MobileSubstrate.dylib",
                "/etc/apt",
                "/private/var/lib/apt",
            ]
            for path in paths {
                if FileManager.default.fileExists(atPath: path) {
                    logger.warning("[Jailbreak] Indicator found: \(path)")
                    return true
                }
            }
            return false
        #endif
    }
}

import Foundation
import OSLog

#if canImport(Contacts)
import Contacts
#endif

// MARK: - Contact Info

public struct ContactInfo: Sendable, Hashable {
    public let name: String
    public let phoneNumber: String?

    public init(name: String, phoneNumber: String?) {
        self.name = name
        self.phoneNumber = phoneNumber
    }
}

// MARK: - Contacts Providing

public protocol ContactsProviding: Sendable {
    var isAvailable: Bool { get }
    func requestPermission() async -> Bool
    func fetchAll() async throws -> [ContactInfo]
}

// MARK: - Contacts Service

public final class ContactsService: ContactsProviding, Sendable {
    private let logger = Logger(subsystem: "com.vade.core", category: "contacts")

    public init() {}

    public var isAvailable: Bool {
        #if canImport(Contacts)
        return true
        #else
        return false
        #endif
    }

    public func requestPermission() async -> Bool {
        #if canImport(Contacts)
        let store = CNContactStore()
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            logger.error("[Contacts] Permission request failed: \(error.localizedDescription)")
            return false
        }
        #else
        return false
        #endif
    }

    public func fetchAll() async throws -> [ContactInfo] {
        #if canImport(Contacts)
        let store = CNContactStore()
        let granted = try await store.requestAccess(for: .contacts)
        guard granted else { return [] }

        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
        ]

        let request = CNContactFetchRequest(keysToFetch: keys)
        var results: [ContactInfo] = []

        try store.enumerateContacts(with: request) { contact, _ in
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            guard !name.isEmpty else { return }
            let phone = contact.phoneNumbers.first?.value.stringValue
            results.append(ContactInfo(name: name, phoneNumber: phone))
        }
        return results
        #else
        return []
        #endif
    }
}

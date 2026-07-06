import Foundation

/// Represents a person with whom the user has debt/credit relationships.
public struct Person: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var phoneNumber: String?
    public var notes: String?
    public var createdAt: Date
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.notes = notes
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
}

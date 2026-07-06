import Foundation

// MARK: - Dependency Registration

public struct ServiceRegistration {
    public let name: String
    public let factory: (Resolver) -> Any
    public let scope: ServiceScope

    public init(name: String, factory: @escaping (Resolver) -> Any, scope: ServiceScope) {
        self.name = name
        self.factory = factory
        self.scope = scope
    }
}

// MARK: - Service Scope

public enum ServiceScope {
    case singleton
    case transient
}

// MARK: - Resolver Protocol

public protocol Resolver {
    func resolve<Service>(_ type: Service.Type) -> Service?
    func resolve<Service>(_ type: Service.Type, name: String) -> Service?
}

// MARK: - Container Implementation

public final class Container {
    var registrations: [ObjectIdentifier: ServiceRegistration] = [:]
    var singletons: [ObjectIdentifier: Any] = [:]

    public init() {}

    @discardableResult
    public func register<Service>(
        _ type: Service.Type,
        scope: ServiceScope = .singleton,
        factory: @escaping (Resolver) -> Service
    ) -> Self {
        let key = ObjectIdentifier(type)
        registrations[key] = ServiceRegistration(
            name: String(describing: type),
            factory: factory,
            scope: scope
        )
        return self
    }

    public func registerInstance<Service>(_ type: Service.Type, instance: Service) {
        let key = ObjectIdentifier(type)
        singletons[key] = instance
        registrations[key] = ServiceRegistration(
            name: String(describing: type),
            factory: { _ in instance },
            scope: .singleton
        )
    }
}

// MARK: - Resolver Conformance

extension Container: Resolver {
    public func resolve<Service>(_ type: Service.Type) -> Service? {
        let key = ObjectIdentifier(type)

        if let singleton = singletons[key] as? Service {
            return singleton
        }

        guard let registration = registrations[key],
              let instance = registration.factory(self) as? Service
        else {
            return nil
        }

        if registration.scope == .singleton {
            singletons[key] = instance
        }

        return instance
    }

    public func resolve<Service>(_ type: Service.Type, name: String) -> Service? {
        resolve(type)
    }
}

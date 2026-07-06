import SwiftUI

/// Base coordinator protocol. Coordinators own navigation state only;
/// no business logic belongs here.
@MainActor
protocol Coordinator: AnyObject {
    var parentCoordinator: (any Coordinator)? { get }
    var childCoordinators: [any Coordinator] { get set }

    func start() -> AnyView
    func addChild(_ coordinator: any Coordinator)
    func removeChild(_ coordinator: any Coordinator)
}

// MARK: - Default Implementations

extension Coordinator {
    func addChild(_ coordinator: any Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeChild(_ coordinator: any Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
}

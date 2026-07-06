import SwiftUI

/// Base coordinator protocol. Coordinators own navigation state only;
/// no business logic belongs here.
@MainActor
protocol Coordinator: AnyObject {
    var parentCoordinator: Coordinator? { get }
    var childCoordinators: [Coordinator] { get set }

    func start() -> AnyView
    func addChild(_ coordinator: Coordinator)
    func removeChild(_ coordinator: Coordinator)
}

// MARK: - Default Implementations

extension Coordinator {
    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
}

# ADR-001: MVVM-C Architecture with Coordinator Pattern

## Status
Accepted

## Context
The application needs a scalable, testable architecture for a single-user iOS app with multiple feature modules (dashboard, debt detail, settings, onboarding). The architecture must support SwiftUI's observation framework (iOS 18+) and Swift 6 strict concurrency.

## Decision
**MVVM-C (Model-View-ViewModel-Coordinator)** is chosen as the primary architectural pattern.

- **Model**: Domain entities and use cases (framework-agnostic)
- **View**: SwiftUI views, rendering only. No business logic.
- **ViewModel**: `@Observable` classes (Observation framework, not `ObservableObject`), annotated with `@MainActor`. State holders that delegate decisions to use cases.
- **Coordinator**: Owns navigation graph, injects dependencies. No business logic.

## Alternatives Considered
- **VIPER**: More boilerplate with limited benefit for SwiftUI. Coordinator already handles routing; Presenter/Interactor layers add ceremony without proportional value.
- **TCA (The Composable Architecture)**: Powerful but heavy 3rd-party dependency. Overkill for a single-user CRUD app.
- **Plain MVVM**: Without Coordinator, navigation logic leaks into views, making reuse and deep-linking harder.

## Consequences
- Strict separation of concerns: Views are thin, ViewModels are thin, Coordinators own navigation only.
- Each feature module is independently testable.
- Coordinator pattern enables centralized navigation control and deep-linking in future phases.

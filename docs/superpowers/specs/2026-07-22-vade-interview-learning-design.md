# Vade Interview Learning Design

## Goal

Enable the project owner to explain and defend Vade's implementation decisions in a technical iOS interview, from individual Swift declarations to the app's full architecture.

## Learner and pace

- Starting point: little or no prior iOS/Swift implementation experience.
- Pace: intensive, approximately five to six focused hours per day.
- Scope: learning and inspection only. The production app is not changed as part of the curriculum.

## Teaching format

Every lesson uses the same evidence-based loop:

1. Explain one concept in plain Turkish, including what problem it solves.
2. Show its exact Vade implementation and dependency context.
3. Contrast it with viable alternatives and state the trade-offs.
4. Practice a concise interview answer, then a deeper follow-up answer.
5. Verify understanding by tracing, testing, or making a disposable local experiment outside the production code path.

The program prioritizes causal understanding over vocabulary memorization. For example, `Codable` is taught as the composition of `Encodable` and `Decodable`; the learner then assesses whether a particular Vade type crosses a serialization boundary and whether its conformance is necessary, sufficient, or incidental.

## Curriculum structure

### Phase 0 — Toolchain and project map (1 day)

Explain macOS/Xcode, Simulator, schemes, build products, Git, Swift Package Manager, Tuist manifests, generated projects, and the boundary between `Project.swift`, `Workspace.swift`, and package-level `Package.swift` files. Trace app launch from `App/Sources/Vade/VadeApp.swift` to `AppCoordinator.swift`.

### Phase 1 — Swift language foundations (5 days)

Cover types, type inference, value versus reference semantics, `struct`, `class`, `enum`, protocols, extensions, access control, optionals, collections, closures, generics, error handling, `Decimal`, and date/value modeling. Use `Packages/Domain` as the primary source because it has the smallest dependency surface.

### Phase 2 — Modern Swift correctness (5 days)

Cover `Codable`, `Encodable`, `Decodable`, `RawRepresentable`, `Hashable`, `Identifiable`, `Equatable`, `Sendable`, property wrappers, `async`/`await`, tasks, cancellation, isolation, `@MainActor`, `nonisolated`, and strict Swift 6 concurrency. Examine why Vade configures strict concurrency in `Project.swift` and how repositories and view models participate.

### Phase 3 — SwiftUI and application state (6 days)

Cover declarative rendering, view identity, `@State`, `@Binding`, `@Environment`, `@AppStorage`, `Observable`, `@MainActor`, navigation, tabs, sheets, lists, animation, localization, accessibility, and rendering/performance. Trace views and view models inside `FeatureDashboard`, `FeatureDebtDetail`, `FeatureSettings`, and onboarding.

### Phase 4 — Persistence and sync (5 days)

Cover SwiftData `@Model`, `ModelContainer`, `ModelContext`, fetch descriptors, predicates, relationships, repository mapping, data integrity, migrations, CloudKit private database sync, offline behavior, and audit trails. Trace `ModelContainerFactory`, persistence models, and repository implementations in `Packages/Data`.

### Phase 5 — Architecture and modularity (5 days)

Cover Clean Architecture as used here, MVVM-C, domain entities, use-case protocols, dependency inversion, constructor injection, composition root, factories, repository pattern, package boundaries, dependency direction, circular-dependency avoidance, and when this architecture is excessive. Trace concrete dependencies from the app target to each package.

### Phase 6 — Platform services and product infrastructure (4 days)

Cover `URLSession`, XML/network decoding and caching, TCMB exchange-rate client behavior, local notifications, Contacts, biometric authentication, Keychain/security APIs, MetricKit, privacy manifests, OSLog/analytics, data export, app lifecycle, WidgetKit, assets, fonts, and localization.

### Phase 7 — Testing and interview simulation (5 days)

Cover Swift Testing syntax and lifecycle, test doubles, in-memory SwiftData, URL protocol mocks, async tests, snapshot strategy, test pyramid, coverage limits, debugging, and review of design risks in the existing code. Finish with progressively harder code-walkthrough interviews: declaration-level questions, feature-flow questions, and architecture/system-design questions.

## Vade-first reference map

| Concern | Primary source |
| --- | --- |
| App composition and lifecycle | `App/Sources/Vade/VadeApp.swift`, `App/Sources/Vade/Coordinators/AppCoordinator.swift` |
| Business model and contracts | `Packages/Domain/Sources/Domain` |
| Database and repositories | `Packages/Data/Sources/Data` |
| Shared services | `Packages/Core/Sources/Core`, `Packages/Networking/Sources/Networking`, `Packages/Observability/Sources/Observability` |
| UI system | `Packages/DesignSystem/Sources/DesignSystem` |
| Product features | `Packages/Feature*/Sources` |
| Build and package configuration | `Project.swift`, `Workspace.swift`, root `Package.swift`, each package `Package.swift` |
| Test evidence | `Packages/*/Tests` |

## Success criteria

The learner can:

- Trace any visible screen to its state owner, view model, domain contract, repository, and persistence/network implementation.
- Explain each important conformance, annotation, property wrapper, and access modifier by its concrete responsibility and trade-off.
- Describe why a dependency exists, why its direction matters, and what breaks if that boundary is ignored.
- Identify at least one limitation or questionable implementation decision rather than presenting the project as flawless.
- Answer both a 30-second summary and detailed follow-up questions without relying on a script.

## Constraints

- Do not claim a technology is used until its source/configuration is verified in this repository.
- Distinguish what the code actually guarantees from what README claims.
- Keep production changes out of the curriculum; use tests, traces, and isolated experiments for practice.

<p align="center">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding1.png" width="120" alt="Vade Logo">
</p>

<h1 align="center">Vade</h1>

<p align="center">
  <strong>Debt tracking, reimagined.</strong><br>
  Multi-currency · iCloud Sync · Physical Gold · Offline-first
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-18+-000?style=flat&logo=apple&logoColor=white">
  <img src="https://img.shields.io/badge/Swift-6-F05138?style=flat&logo=swift&logoColor=white">
  <img src="https://img.shields.io/badge/SwiftUI-✓-007AFF?style=flat">
  <img src="https://img.shields.io/badge/SwiftData-✓-5AC8FA?style=flat">
  <img src="https://img.shields.io/badge/CloudKit-✓-FF9500?style=flat">
  <img src="https://img.shields.io/badge/License-Proprietary-red">
</p>

<br>

---

## 📱 Screenshots

<table>
  <tr>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding1.png" width="140" alt="Onboarding 1"><br>
      <sub>Welcome</sub>
    </td>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding2.png" width="140" alt="Onboarding 2"><br>
      <sub>Track</sub>
    </td>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding3.png" width="140" alt="Onboarding 3"><br>
      <sub>Currencies</sub>
    </td>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding4.png" width="140" alt="Onboarding 4"><br>
      <sub>iCloud Sync</sub>
    </td>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/dashboard.png" width="140" alt="Dashboard"><br>
      <sub>Dashboard</sub>
    </td>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/quickAdd.png" width="140" alt="Quick Add"><br>
      <sub>Quick Add</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/addPerson.png" width="140" alt="Add Person"><br>
      <sub>Add Person</sub>
    </td>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/people.png" width="140" alt="People"><br>
      <sub>People</sub>
    </td>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/statistics.png" width="140" alt="Statistics"><br>
      <sub>Statistics</sub>
    </td>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/exchangeRates.png" width="140" alt="Exchange Rates"><br>
      <sub>Exchange Rates</sub>
    </td>
    <td align="center" width="16%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/settings.png" width="140" alt="Settings"><br>
      <sub>Settings</sub>
    </td>
  </tr>
</table>

---

## 🏗 Architecture & Design Patterns

| Concept | Implementation |
|---------|---------------|
| **Clean Architecture** | 3-layer separation: Domain → Data → Presentation |
| **MVVM-C** | Model-View-ViewModel-Coordinator pattern |
| **Modular Architecture** | 12 isolated SPM packages, incremental compilation |
| **Repository Pattern** | UseCase protocols in Domain, implementations in Data |
| **Protocol-Oriented Design** | Dependency inversion via protocol abstractions |
| **Dependency Injection** | Constructor injection throughout the stack |
| **View-First Architecture** | Views drive lifecycle, ViewModels handle business logic |
| **Factory Pattern** | Coordinator creates view controllers and injects dependencies |

```mermaid
graph TD
    Presentation[Presentation Layer<br/>SwiftUI Views + ViewModels] --> Domain[Domain Layer<br/>Pure Swift, No UI Dependencies]
    Presentation --> Data[Data Layer<br/>SwiftData + CloudKit]
    Data --> Domain
    Domain --> Foundation
```

### 🔷 MVVM-C in Practice

```swift
// View (SwiftUI) — thin, no business logic
struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    
    var body: some View {
        content(vm)
            .task { await vm.loadData() }
    }
}

// ViewModel — business logic + state management
final class DashboardViewModel: ObservableObject {
    @Published private(set) var persons: [Person] = []
    private let personRepo: FetchPersonsUseCase   // Protocol, not concrete
    
    @MainActor
    func loadData() async {
        let persons = try? await personRepo.execute()
        // ... calculation logic
    }
}

// Coordinator — navigation flows
struct AppCoordinator: View {
    @State private var showOnboarding = true
    
    var body: some View {
        if showOnboarding {
            OnboardingView(onComplete: { showOnboarding = false })
        } else {
            MainTabView()
        }
    }
}
```

### 🔷 12 Modular SPM Packages

```
Packages/
├── Domain/           # Pure Swift models, enums, protocols — zero dependencies
├── Data/             # SwiftData repositories, CloudKit integration
├── Core/             # LanguageManager, SecurityServices, Utilities
├── Networking/       # URLSession + async/await, XML parsing, caching
├── DesignSystem/     # Component library: ColorTokens, Typography, Components
├── Observability/    # Analytics & logging abstraction
├── FeatureDashboard/ # Dashboard, charts, rates ticker
├── FeatureDebtDetail/# Debt records, payment management, timeline
├── FeatureOnboarding/# Onboarding flow (4-step wizard)
├── FeatureSettings/  # Settings, data management, export
├── FeatureWidget/    # Home screen widget (WidgetKit)
└── Project.swift     # Tuist manifest
```

**Why 12 packages?** Incremental build performance. Change one feature → only that package recompiles. Each package has isolated tests and zero unintended dependencies.

### 🔷 Clean Architecture — Layer Separation

```
┌─────────────────────────────────┐
│   Presentation (Feature*)       │
│   SwiftUI Views, ViewModels     │
├─────────────────────────────────┤
│   Domain (Pure Swift)           │
│   Entities, UseCase Protocols   │ ← No UIKit/ SwiftUI import
├─────────────────────────────────┤
│   Data                          │
│   Repository Implementations    │
│   @Model classes, CloudKit      │
└─────────────────────────────────┘
```

---

## 🧪 Testing Strategy

| Area | Framework | Coverage | Technique |
|------|-----------|----------|-----------|
| Domain Calculations | Swift Testing | **86%+** | Parameterized `@Test`, property-based |
| Repository / Data | Swift Testing | **84%+** | In-memory SwiftData container |
| Networking | Swift Testing | **89%+** | Mock URLProtocol |
| Analytics Events | Swift Testing | **100%** | Whitelist validation |
| UI Components | Swift Testing | Snapshot | Native `ImageRenderer` (zero deps) |
| ViewModels | Swift Testing | Full | Protocol mocks, async assertions |

**Testing principles:**
- **No XCTest** — fully migrated to Swift Testing (`@Test`, `#expect`)
- **No third-party test dependencies** — mock manually, snapshot natively
- **Domain tests in isolation** — Domain package has zero imports beyond Foundation
- **ViewModels tested with protocol mocks** — every dependency is an injected protocol
- **CI enforced** — GitHub Actions runs all tests on every push and PR

```swift
@Test("Currency conversion preserves precision")
func testCurrencyConversion() {
    let result = CurrencyConverter.convert(100, from: .usd, to: .tryCoin, rate: 29.5)
    #expect(result == 2950)
}

@Test("Installment calculation distributes correctly")
func testInstallmentCalculation(amount: Decimal, count: Int) {
    let installments = InstallmentCalculator.calculate(amount, installments: count)
    #expect(installments.count == count)
    #expect(installments.reduce(0, +) == amount)
}
```

---

## ⚡️ Swift 6 Strict Concurrency

Complete **data-race safety at compile time** — zero runtime crashes from concurrent access.

| Technique | Usage |
|-----------|-------|
| `Sendable` | All model types conform to Sendable |
| `@MainActor` | SwiftData operations, SwiftUI ViewModels |
| `async/await` | Structured concurrency throughout networking and data layers |
| `Actor isolation` | Avoided in favor of structs + Sendable (no deadlock risk) |
| `nonisolated` | Shared singletons accessible from any context |
| `@preconcurrency import` | Gradual adoption for Foundation types |

```swift
// Everything is Sendable — guaranteed thread-safe
public struct DebtRecord: Sendable {
    public let id: UUID
    public let amount: Decimal
    public let kind: CurrencyKind
    // ...
}

// ViewModels run on MainActor — safe SwiftData access
@MainActor
final class DashboardViewModel {
    nonisolated static let shared = MainActor.assumeIsolated { DashboardViewModel() }
}
```

---

## 💾 SwiftData + CloudKit (No Backend)

```swift
@Model
final class DebtRecordModel {
    var amount: Decimal
    var kindRawValue: String
    var directionRawValue: String
    @Relationship(inverse: \PersonModel.debts) var person: PersonModel?
}
```

| Capability | Implementation |
|------------|---------------|
| **Local Persistence** | SwiftData `@Model` with `@Relationship` |
| **Cloud Sync** | CloudKit Private Database (automatic, user's iCloud) |
| **Conflict Resolution** | Append-only audit log + SwiftData merge policy |
| **Schema Constraints** | Manual `CKRecord` configuration (unique, required) |
| **Offline Mode** | Full offline functionality, background sync on reconnect |
| **Audit Trail** | Every mutation recorded in append-only `AuditEntryModel` |

**Why no backend?** Every user's data stays in their own iCloud. Zero server cost. Zero privacy liability. Zero maintenance.

---

## 🔐 Security

| Feature | Implementation |
|---------|---------------|
| **Biometric Auth** | Face ID / Touch ID via `LAContext` |
| **App Lock** | Scene-phase background blur |
| **No Certificate Pinning** | ADR-003: Deliberate choice for network flexibility |
| **No Backend** | User data never leaves their iCloud |

---

## 🎨 Design System (In-House Component Library)

```
DesignSystem/
├── ColorTokens.swift       # Dark-only financial palette
├── Typography.swift        # Enum-based type scale + Jakarta Sans
├── Spacing+Radius.swift    # 4px base grid system
├── Elevation.swift         # Shadow levels (level1, level2, level3)
├── GlassCard.swift         # Premium glass-morphism card
├── PremiumBalanceCard.swift # Hero balance display
├── StatCard.swift          # Statistical metric card
├── ActionPill.swift        # Interactive action button
├── RateTile.swift          # Exchange rate display
├── CurrencyIconView.swift  # Currency-specific icons
├── FinanceBackgroundAnimation.swift # Canvas-based animated bg
├── UndoToastView.swift     # Undo action bar
├── AvatarView.swift        # Gradient avatar with initials
├── ShimmerView.swift       # Skeleton loading animation
├── EntranceAnimation.swift # .entrance(.scale/fade/up/leading) modifier
└── LedgerRowView.swift     # Reusable ledger row
```

**Key decisions:**
- **Dark-only palette** — financial apps benefit from dark UI; `ColorTokens` defines every color
- **4px grid** — `Spacing.xs = 4, .s = 8, .m = 12, .l = 16, .xl = 24, .xxl = 32`
- **Custom font** — Jakarta Sans for headings, system SF for body
- **No third-party UI library** — every component hand-crafted for consistency
- **`.entrance()` modifier** — custom `ViewModifier` for entrance animations (`.fade`, `.scale`, `.up`, `.leading` with configurable delay/duration)
- **`.premiumPress()` modifier** — button press animation with spring response and haptic feedback
- **`.elevation()` modifier** — shadow levels (`level1`, `level2`, `level3`) matching Material Design 3

---

## 📡 Networking

```
Networking/
├── ExchangeRateClient.swift    # TCMB XML → parsed rates
├── ExchangeRateProviding.swift # Protocol for testability
├── RatesCache.swift            # 30-minute in-memory cache
└── CurrencyConverter.swift     # Multi-currency conversion
```

**Implementation details:**
- **URLSession + async/await** — structured concurrency, no Combine needed
- **Protocol abstraction** — `ExchangeRateProviding` protocol for DI and testing
- **Caching layer** — 30-minute TTL (TCMB updates once daily)
- **Offline fallback** — cached rates displayed when offline
- **Physical gold pricing** — API fetches XAU (troy ounce) → gram price → multiply by physical type weight

---

## 📦 Package Dependencies & Module Graph

```
App (Vade)
├── FeatureDashboard
│   ├── Domain, Data, DesignSystem, Networking, Observability
├── FeatureDebtDetail
│   ├── Domain, Data, DesignSystem, Observability
├── FeatureOnboarding
│   ├── DesignSystem, Core
├── FeatureSettings
│   ├── DesignSystem, Core, Domain, Data, Observability
├── FeatureWidget
│   ├── Core, Domain, Observability, DesignSystem
├── Core
│   ├── (Foundation-only, no UI)
├── Domain
│   ├── (Foundation-only, no UI)
├── Data
│   ├── Domain
├── DesignSystem
│   ├── Core
├── Networking
│   ├── Foundation
└── Observability
    └── OSLog + Firebase Analytics
```

---

## 🌐 Localization

| Language | Status |
|----------|--------|
| 🇹🇷 Turkish | Complete (source language) |
| 🇬🇧 English | Complete |

- **271 localized strings** across the app
- **`.xcstrings` format** — Xcode 15 native, compile-time validation
- **LanguageManager** — custom runtime language switching (no app restart)
- **All strings `locale:`-aware** — `String(localized:locale:)` with explicit locale propagation

---

## 🎯 Features (Product)

| | |
|---|---|
| 💰 **Multi-Currency** | TRY, USD, EUR, and physical gold (Gram, Quarter, Half, Full, Republic) |
| 🔄 **iCloud Sync** | SwiftData + CloudKit — offline-first, no backend |
| 📊 **Live Rates** | TCMB exchange rates with 30-min cache and offline fallback |
| 🏅 **Physical Gold** | Auto-conversion from gram price to Çeyrek, Yarım, Tam, Cumhuriyet |
| 📅 **Reminders** | Local notifications for due and overdue debts |
| 🔐 **Privacy** | Face ID / Touch ID lock with background blur |
| 📄 **Export** | CSV and PDF (PDFKit) |
| 📱 **Widget** | Home screen widget via WidgetKit (systemSmall, systemMedium) |
| ♿ **Accessibility** | VoiceOver, Dynamic Type, `.accessibilityLabel`/`Hint` |
| 🌙 **Design** | Dark-only premium UI with canvas animations |
| 🌐 **Bilingual** | Turkish & English with runtime switching |
| 📝 **Audit Trail** | Append-only immutable log for every mutation |

---

## 🛠 Tech Stack — Full Reference

| Category | Technology | Purpose |
|----------|-----------|---------|
| Language | **Swift 6** | Strict concurrency, Sendable, no data races |
| UI Framework | **SwiftUI** | Declarative UI, iOS 18+ |
| Architecture | **MVVM-C + Clean Architecture** | Modular, testable, separated concerns |
| Project Structure | **Modular SPM** | 12 packages, incremental builds |
| Persistence | **SwiftData** | Native Swift ORM, `@Model`, `@Relationship` |
| Cloud Sync | **CloudKit Private DB** | User's iCloud, zero backend |
| Charts | **Swift Charts** | `Chart`, `BarMark`, `LineMark`, `SectorMark` |
| Widgets | **WidgetKit** | `TimelineProvider`, `StaticConfiguration` |
| Networking | **URLSession + async/await** | Structured concurrency |
| Testing | **Swift Testing** | `@Test`, parameterized, no XCTest |
| Snapshot Testing | **ImageRenderer** | Native, zero dependencies |
| Linting | **SwiftLint + SwiftFormat** | Code style enforcement |
| Project Generation | **Tuist** | Xcode project as code (`.swift`) |
| CI/CD | **GitHub Actions** | Build + test on every push |
| Analytics | **Firebase + OSLog** | Observability and debugging |
| Biometrics | **LocalAuthentication** | Face ID, Touch ID |
| PDF Generation | **PDFKit** | Native PDF export |
| Localization | **xcstrings + LanguageManager** | Runtime language switching |
| Accessibility | **UIAccessibility + SwiftUI** | VoiceOver, Dynamic Type, WCAG |

---

## 📊 Code Quality Metrics

```json
{
  "swift_version": "6.0",
  "packages": 12,
  "test_coverage": "86%+",
  "localized_strings": 272,
  "languages": ["Turkish", "English"],
  "concurrency_model": "strict",
  "architecture": ["MVVM-C", "Clean Architecture", "Modular"],
  "ci": "GitHub Actions",
  "project_gen": "Tuist",
  "data_race_free": true
}
```

---

## 🚀 Getting Started

```bash
git clone https://github.com/burak-bilgen/Vade.git
cd Vade

# Install Tuist (project generation)
brew install tuist
tuist generate

open Vade.xcworkspace
```

Requires **Xcode 16+** and **iOS 18+ SDK**.

---

## 📄 License

All rights reserved. Professional portfolio project.

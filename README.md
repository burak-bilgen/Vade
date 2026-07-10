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

Vade is a debt tracking app for iOS that helps you manage who owes you and who you owe — across multiple currencies, physical gold, and with full iCloud sync. No backend, no servers, no subscription.

## 🎯 Features

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
| ♿ **Accessibility** | VoiceOver, Dynamic Type and accessibility labels |
| 🌙 **Dark Design** | Premium dark-only UI with canvas animations |
| 🌐 **Bilingual** | Turkish & English with runtime switching |
| 📝 **Audit Trail** | Append-only immutable log for every mutation |

## 📱 Screenshots

### 👋 Onboarding

Welcome flow that introduces the app, explains tracking, currencies, and iCloud sync across 4 screens.

<p align="center">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding1.png" width="180" alt="Onboarding 1">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding2.png" width="180" alt="Onboarding 2">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding3.png" width="180" alt="Onboarding 3">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding4.png" width="180" alt="Onboarding 4">
</p>

### 🏠 Dashboard

Total balances, recent activity, and a Quick Add sheet for fast transaction entry.

<p align="center">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/dashboard.png" width="200" alt="Dashboard">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/quickAdd.png" width="200" alt="Quick Add">
</p>

### 👥 People

Track debts per person with full history, payment plans, and contact integration.

<p align="center">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/people.png" width="200" alt="People List">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/addPerson.png" width="200" alt="Add Person">
</p>

### 📊 Analytics

Charts, live exchange rates, and a debt payoff assistant that tells you who to pay first.

<p align="center">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/statistics.png" width="200" alt="Statistics">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/exchangeRates.png" width="200" alt="Exchange Rates">
</p>

### ⚙️ Settings

Data management, export, language switching, and privacy controls.

<p align="center">
  <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/settings.png" width="200" alt="Settings">
</p>

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

### 12 Modular SPM Packages

```
Packages/
├── Domain/           # Pure Swift models, enums, protocols — zero dependencies
├── Data/             # SwiftData repositories, CloudKit integration
│   └── depends on: Domain
├── Core/             # LanguageManager, SecurityServices, Utilities
├── Networking/       # URLSession + async/await, XML parsing, caching
├── DesignSystem/     # Component library: ColorTokens, Typography, Components
│   └── depends on: Core
├── Observability/    # Analytics & logging abstraction (OSLog + Firebase)
├── FeatureDashboard/ # Dashboard, charts, rates ticker
│   └── depends on: Domain, Data, DesignSystem, Networking, Observability
├── FeatureDebtDetail/# Debt records, payment management, timeline
│   └── depends on: Domain, Data, DesignSystem, Observability
├── FeatureOnboarding/# Onboarding flow (4-step wizard)
│   └── depends on: DesignSystem, Core
├── FeatureSettings/  # Settings, data management, export
│   └── depends on: DesignSystem, Core, Domain, Data, Observability
├── FeatureWidget/    # Home screen widget (WidgetKit)
│   └── depends on: Core, Domain, Observability, DesignSystem
└── Project.swift     # Tuist manifest
```

12 packages, zero circular dependencies. Change one feature, only that package recompiles. Each package has its own isolated tests with no risk of leaking into another.

## 🧪 Testing Strategy

| Area | Framework | Coverage | Technique |
|------|-----------|----------|-----------|
| Domain Calculations | Swift Testing | 86%+ | Parameterized tests, property-based |
| Repository / Data | Swift Testing | 84%+ | In-memory SwiftData container |
| Networking | Swift Testing | 89%+ | Mock URLProtocol |
| Analytics Events | Swift Testing | 100% | Whitelist validation |
| UI Components | Swift Testing | Snapshot | Native ImageRenderer, zero dependencies |
| ViewModels | Swift Testing | Full | Protocol mocks, async assertions |

All tests are written with Swift Testing — no XCTest, no third-party test libraries. The Domain package has zero dependencies beyond Foundation, and so do its tests. CI runs the full suite on every push.

## ⚡️ Swift 6 Strict Concurrency

Data-race safety guaranteed at compile time. Zero runtime crashes from concurrent access.

| Technique | Usage |
|-----------|-------|
| Sendable | All model types conform to Sendable |
| @MainActor | SwiftData operations, SwiftUI ViewModels |
| async/await | Structured concurrency throughout networking and data layers |
| Actor isolation | Avoided in favor of structs + Sendable (no deadlock risk) |
| nonisolated | Shared singletons accessible from any context |
| @preconcurrency import | Gradual adoption for Foundation types |

All models are Sendable. ViewModels use @MainActor for safe SwiftData access. No Combine in the networking layer — everything is async/await. No actors used anywhere: struct + Sendable eliminates deadlock risk entirely.

## 💾 SwiftData + CloudKit (No Backend)

Local persistence with SwiftData, automatic iCloud sync through CloudKit Private Database. User data never leaves their iCloud.

| Capability | Implementation |
|------------|---------------|
| **Local Persistence** | SwiftData @Model with @Relationship |
| **Cloud Sync** | CloudKit Private Database (automatic, user's iCloud) |
| **Conflict Resolution** | Append-only audit log + SwiftData merge policy |
| **Schema Constraints** | Manual CKRecord configuration (unique, required) |
| **Offline Mode** | Full offline functionality, background sync on reconnect |
| **Audit Trail** | Every mutation recorded in append-only AuditEntryModel |

Why no backend? Every user's data stays in their own iCloud. Zero server cost, zero privacy liability, zero maintenance. No sign-up, no password, no vendor lock-in.

## 🔐 Security

| Feature | Implementation |
|---------|---------------|
| **Biometric Auth** | Face ID / Touch ID via LAContext |
| **App Lock** | Scene-phase background blur |
| **No Certificate Pinning** | ADR-003: deliberate choice for network flexibility |

## 🎨 Design System (In-House Component Library)

Every component is hand-crafted — no third-party UI library used. Dark-only palette chosen specifically for financial apps, Jakarta Sans as a custom heading font, and a 4px grid system for consistent spacing.

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

Key custom modifiers:
- **.entrance()** — entrance animation with scale, fade, up, or leading variants, configurable delay and duration
- **.premiumPress()** — button press animation with spring response and haptic feedback
- **.elevation()** — shadow levels matching Material Design 3 (level1, level2, level3)

## 📡 Networking

Fetches XML from TCMB (Central Bank of Turkey), parses it, and caches for 30 minutes. Falls back to cached rates when offline.

```
Networking/
├── ExchangeRateClient.swift    # TCMB XML → parsed rates
├── ExchangeRateProviding.swift # Protocol for testability
├── RatesCache.swift            # 30-minute in-memory cache
└── CurrencyConverter.swift     # Multi-currency conversion
```

URLSession + async/await for structured concurrency. Protocol abstraction for testability. Physical gold pricing flows from XAU (troy ounce) → gram → Çeyrek/Yarım/Tam/Cumhuriyet.

## 🌐 Localization

| Language | Status |
|----------|--------|
| 🇹🇷 Turkish | Complete (source language) |
| 🇬🇧 English | Complete |

271 localized strings across the app. xcstrings format for compile-time validation. LanguageManager enables runtime language switching without app restart. All strings are locale-aware with explicit locale propagation.

## 🛠 Tech Stack

| Category | Technology | Purpose |
|----------|-----------|---------|
| Language | **Swift 6** | Strict concurrency, Sendable, no data races |
| UI Framework | **SwiftUI** | Declarative UI, iOS 18+ |
| Architecture | **MVVM-C + Clean Architecture** | Modular, testable, separated concerns |
| Project Structure | **Modular SPM** | 12 packages, incremental builds |
| Persistence | **SwiftData** | Native Swift ORM, @Model, @Relationship |
| Cloud Sync | **CloudKit Private DB** | User's iCloud, zero backend |
| Charts | **Swift Charts** | Chart, BarMark, LineMark, SectorMark |
| Widgets | **WidgetKit** | TimelineProvider, StaticConfiguration |
| Networking | **URLSession + async/await** | Structured concurrency |
| Testing | **Swift Testing** | @Test, parameterized, no XCTest |
| Snapshot Testing | **ImageRenderer** | Native, zero dependencies |
| Linting | **SwiftLint + SwiftFormat** | Code style enforcement |
| Project Generation | **Tuist** | Xcode project as code |
| CI/CD | **GitHub Actions** | Build + test on every push |
| Analytics | **Firebase + OSLog** | Observability and debugging |
| Biometrics | **LocalAuthentication** | Face ID, Touch ID |
| PDF Generation | **PDFKit** | Native PDF export |
| Localization | **xcstrings + LanguageManager** | Runtime language switching |
| Accessibility | **UIAccessibility + SwiftUI** | VoiceOver, Dynamic Type, WCAG |

## 📄 License

All rights reserved. Proprietary.

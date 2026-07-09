# Vade

Track who owes you and who you owe. Offline-first, iCloud-synced across devices, multi-currency with physical gold support. Built for the Turkish market.

## What it does

Know exactly how much you're owed, what currency it's in, and when it's due. No spreadsheets, no mental math.

- Track debts and receivables in TRY, USD, EUR, and physical gold
- Gold types: gram, çeyrek, yarım, tam, cumhuriyet (auto-converted from gram price)
- Live exchange rates from TCMB with offline fallback
- Partial payments, installments, automatic balance recalculation
- Quick actions per person: call, message, share
- Due date reminders (local notifications, no server)
- Face ID / Touch ID app lock with background blur
- Append-only audit trail for every mutation
- PDF/CSV export
- Home screen widget
- 6 languages: Turkish, English, Spanish, Mandarin Chinese, Hindi, Arabic (RTL)
- VoiceOver and Dynamic Type support

## Architecture

**iOS 18+ · Swift 6 · Strict concurrency** (complete data-race safety at compile time).

MVVM but not the "view model owns everything" kind. View-first: views trust SwiftUI's natural lifecycle, view models only handle business logic and state. Coordinator pattern covers navigation flows where NavigationStack falls short.

The project is split into 12 SPM packages. Reason: incremental build performance. Change one feature, only that package recompiles. Each package has its own tests, runnable in isolation.

### SwiftData + CloudKit

No backend. SwiftData on device, CloudKit private database in the cloud. User's own iCloud account handles sync.

- `@Model` classes map automatically to CloudKit records
- Schema constraints (unique, required) configured manually via `CKRecord`
- Conflict resolution: SwiftData's built-in merge policy is sufficient because the append-only audit log makes data loss virtually impossible
- No internet? Works locally. Internet comes back? Syncs in the background. User never notices.

### Design System (in-house component library)

Everything lives in the `DesignSystem` package:

- **ColorTokens**: Dark-only palette. Financial apps look better in dark mode, so we committed to it.
- **Spacing/Radius system**: 4px base grid. `Spacing.xs = 4`, `Spacing.s = 8`, `Spacing.m = 12`... Fully scalable.
- **Typography**: System font + Jakarta Sans (custom). `Typography.font(for:)` enum-based type scale.
- **Components**: GlassCard, PremiumBalanceCard, StatCard, ActionPill, RateTile, MetricTile, and more. Every component is reusable, unit-testable, and has snapshot tests.
- **FinanceBackgroundAnimation**: Canvas-based animated background for that premium finance app feel.

### Domain / Data separation

The Domain package contains only Swift models and calculation logic. It imports Foundation but knows nothing about SwiftUI. This means:

- Domain can be used on any platform
- Testing is trivial (no UI, no dependencies)
- Everything is `Sendable` for thread safety

The Data package abstracts everything SwiftData-related behind a repository pattern. UseCase protocols are defined in Domain, implementations live in Data. ViewModels depend on UseCases, never on SwiftData directly.

### Networking

`ExchangeRateClient`: Parses TCMB XML, runs conversions through `CurrencyConverter`. `RatesCache` holds a 30-minute cache because TCMB updates rates once per day anyway. Offline? Shows cached data.

### Concurrency strategy

Swift 6 strict concurrency. We chose structs + Sendable over actors because:

- Actors introduce deadlock risk (especially with reentrancy)
- Our data model is mostly immutable
- SwiftData `@Model` types run on `@MainActor` anyway, no need for actor isolation

### Physical gold pricing

A separate `CurrencyKind` enum case for each physical gold type. Conversions: çeyrek = 1.75g, yarım = 3.5g, tam = 7.0g, cumhuriyet = 7.216g. The API fetches XAU (troy ounce) and divides by gram, then multiplies by each type's gram weight.

## Testing strategy

Swift Testing framework (`@Test`, parameterized). No XCTest.

- **Domain calculations**: InstallmentCalculator, CurrencyConverter, balance aggregation -- 86%+ coverage
- **Repository/Data**: In-memory SwiftData container for integration tests -- 84%+ coverage
- **Networking**: Mock URLProtocol for API tests -- 89%+ coverage
- **Observability**: Analytics event whitelist validation -- 100% coverage
- **Snapshot**: Native `ImageRenderer`-based snapshot tests for UI components (zero third-party dependencies)
- **ViewModels**: Full unit test coverage

## Tech stack

| Layer | Choice | Why |
|-------|--------|-----|
| UI | SwiftUI | iOS 18 minimum, SwiftUI is mature enough |
| Language | Swift 6 | Strict concurrency, Sendable |
| Architecture | MVVM-C | Testable, SwiftUI-compatible navigation |
| Database | SwiftData | Apple's next-gen persistence, CloudKit built-in |
| Sync | CloudKit Private DB | No backend, user's own iCloud |
| Network | URLSession + async/await | No extra dependencies, OS-level |
| Testing | Swift Testing | Apple's XCTest successor |
| Charts | Swift Charts | iOS 16+, native |
| Widget | WidgetKit | iOS 14+ |
| Project Gen | Tuist | Keep Xcode project files out of git |

## Getting started

```bash
git clone https://github.com/burak-bilgen/Vade.git
cd vade

brew install tuist
tuist generate

open Vade.xcworkspace
```

Requires Xcode 16+ and iOS 18+ SDK.


## License

All rights reserved. Professional portfolio project.

# Vade

Personal debt/credit tracking app — offline-first, iCloud-synced, built for the Turkish market with multi-currency and gold tracking.

> **Status:** Phase 0–5 complete · 55 tests passing · 12 SPM packages · Zero hardcoded strings

## Features
- Track money lent to and borrowed from contacts (manual or from address book)
- Multi-currency support: TRY, USD, EUR + physical gold types (gram, çeyrek, yarım, tam, cumhuriyet)
- Live exchange rates (TCMB) and gold prices with offline fallback
- Partial payment tracking with automatic balance calculation
- Due date reminders with local notifications (rich, actionable)
- Face ID / Touch ID app lock
- Append-only audit trail for all data changes
- PDF/CSV export
- Home screen widget
- 6 languages: Turkish, English, Spanish, Mandarin Chinese, Hindi, Arabic (RTL)
- Accessibility: VoiceOver, Dynamic Type, WCAG AA color contrast

## Architecture
- **iOS 18+** · Swift 6 · Strict concurrency (complete data-race safety)
- **SwiftUI** with MVVM-C (Coordinator pattern)
- **SwiftData + CloudKit** — automatic multi-device sync, no backend server
- **Modular SPM packages**: Core, DesignSystem, DIContainer, Domain, Data, Networking, Observability, FeatureOnboarding, FeatureDashboard, FeatureDebtDetail, FeatureSettings, FeatureWidget
- **Custom Design System**: Plus Jakarta Sans + JetBrains Mono fonts, brass/ink palette, ledger-inspired UI
- **Analytics**: Firebase Crashlytics + type-safe Analytics event whitelist (personally-identifiable data never leaves the device)
- **CI/CD**: GitHub Actions — build, test (Swift Testing), SwiftLint, SwiftFormat, coverage threshold, commit format check

## Tech Stack
| Layer | Choice |
|-------|--------|
| UI | SwiftUI (iOS 18+) |
| Language | Swift 6 (strict concurrency) |
| Architecture | MVVM-C |
| Persistence | SwiftData |
| Sync | CloudKit (private database) |
| DI | Custom protocol-based container |
| Networking | URLSession + async/await |
| Testing | Swift Testing (`@Test`, parametrized) + XCUITest + swift-snapshot-testing |
| Charts | Swift Charts |
| Widget | WidgetKit |
| Lint/Format | SwiftLint + SwiftFormat |
| CI | GitHub Actions |
| Crash/Analytics | Firebase Crashlytics + Analytics |
| Ads | Google AdMob (non-personalized fallback) |
| Project Gen | Tuist |

## Getting Started
```bash
# Clone
git clone https://github.com/<user>/vade.git
cd vade

# Install tools
brew install swiftlint swiftformat tuist

# Generate Xcode project
tuist generate

# Build & run
open Vade.xcworkspace
```

## License
All rights reserved. Source code is a professional portfolio project.

## Documentation
- [ADR-001: MVVM-C Architecture](docs/adr/001-mvvm-c-architecture.md)
- [ADR-002: SwiftData + CloudKit](docs/adr/002-swiftdata-cloudkit.md)
- [ADR-003: No Certificate Pinning](docs/adr/003-no-certificate-pinning.md)
- [ADR-004: CloudKit Schema Constraints](docs/adr/004-cloudkit-schema-constraints.md)
- [ADR-005: Liquid Glass Adoption](docs/adr/005-liquid-glass-adoption.md)
- [ADR-006: Firebase Analytics Event Whitelist](docs/adr/006-firebase-analytics-event-whitelist.md)
- [ADR-007: App Name "Vade"](docs/adr/007-app-name-vade.md)

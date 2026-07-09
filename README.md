# Vade

Personal debt/credit tracking app — offline-first, iCloud-synced, built for the Turkish market with multi-currency and gold tracking.

## Features
- Track money lent to and borrowed from contacts
- Multi-currency: TRY, USD, EUR + physical gold types (gram, çeyrek, yarım, tam, cumhuriyet)
- Live exchange rates (TCMB) and gold prices with offline fallback
- Partial payment tracking with automatic balance calculation
- Quick actions: call, message, and share from person detail
- Due date reminders with local notifications
- Face ID / Touch ID app lock with background blur
- Append-only audit trail for all data changes
- PDF/CSV export
- Home screen widget
- 6 languages: Turkish, English, Spanish, Mandarin Chinese, Hindi, Arabic (RTL)
- Haptic feedback on key interactions
- Accessibility: VoiceOver support, Dynamic Type

## Architecture
- **iOS 18+** · Swift 6 · Strict concurrency (complete data-race safety)
- **SwiftUI** with MVVM + View-first architecture
- **SwiftData + CloudKit** — automatic multi-device sync, no backend server
- **12 SPM packages**: Core, DesignSystem, Domain, Data, Networking, Observability, FeatureOnboarding, FeatureDashboard, FeatureDebtDetail, FeatureSettings, FeatureWidget
- **Custom Design System**: Color tokens, spacing/radius system, typography helpers, glassmorphism cards
- **HapticFeedback**: Light/medium impact, notification success/error, selection feedback on all key interactions
- **Analytics**: Type-safe event whitelist (personally-identifiable data never leaves the device)
- **Project generation**: Tuist

## Screens
- **Dashboard**: Gradient balance card, exchange rate ticker, 2×2 quick actions, monthly stats, upcoming payments, recent activity, currency distribution chart
- **People**: Searchable person list with balance chips, segment filter (receivable/payable), quick-add person sheet
- **Person Detail**: Balance card, call/message/share quick actions, debt summary chips, timeline view, record payment sheet
- **Settings**: Language, theme, notifications, biometric lock, data management (export, delete)
- **Onboarding**: Feature cards, iCloud status check, privacy disclaimer

## Tech Stack
| Layer | Choice |
|-------|--------|
| UI | SwiftUI (iOS 18+) |
| Language | Swift 6 (strict concurrency) |
| Architecture | MVVM |
| Persistence | SwiftData |
| Sync | CloudKit (private database) |
| Networking | URLSession + async/await |
| Testing | Swift Testing (`@Test`, parametrized) |
| Charts | Swift Charts |
| Widget | WidgetKit |
| Project Gen | Tuist |

## Getting Started
```bash
# Clone
git clone https://github.com/<user>/vade.git
cd vade

# Install tools
brew install tuist

# Generate Xcode project
tuist generate

# Build & run
open Vade.xcworkspace
```

## Testing & Code Coverage
Vade uses Swift Testing framework for logic/integration verification and a custom, lightweight, native Swift snapshot testing utility for visual assurance.

### Code Coverage Summary
Core logic and calculations have high code coverage:
- **Observability.framework** : `100.00%` (37/37 lines)
- **Networking.framework**    : `89.00%` (186/209 lines)
- **Domain.framework**        : `86.44%` (102/118 lines)
- **Data.framework**          : `84.47%` (348/412 lines)

*Note: UI and view-layout targets have visual snapshot tests, and ViewModels are fully unit-tested to ensure reliable functionality.*

### Test Suite Structure
1. **Unit & Logic Tests**:
   - Parameterized, asynchronous tests for rate conversion calculations (`CurrencyConverter`, `TCMB XML Parser`, `RatesCache`).
   - Business calculations (`InstallmentCalculator`, `Balance Calculations`, `Payment Recording`).
2. **SwiftData / Integration Tests**:
   - `BalanceRepositoryTests` verifies multi-currency conversion, partial payments, and net balance aggregation across multiple currencies with an in-memory SwiftData container.
3. **Visual Snapshot Tests**:
   - Native, dependency-free `ViewSnapshotter` renders SwiftUI views (e.g., `ActionPill`, `StatCard`, `GlassCard`) using `ImageRenderer` at `@2x` retina scale and asserts byte-by-byte visual equality against recorded reference PNGs.

## Documentation
- [ADR-001: MVVM-C Architecture](docs/adr/001-mvvm-c-architecture.md)
- [ADR-002: SwiftData + CloudKit](docs/adr/002-swiftdata-cloudkit.md)
- [ADR-003: No Certificate Pinning](docs/adr/003-no-certificate-pinning.md)
- [ADR-004: CloudKit Schema Constraints](docs/adr/004-cloudkit-schema-constraints.md)
- [ADR-005: Liquid Glass Adoption](docs/adr/005-liquid-glass-adoption.md)
- [ADR-006: Firebase Analytics Event Whitelist](docs/adr/006-firebase-analytics-event-whitelist.md)
- [ADR-007: App Name "Vade"](docs/adr/007-app-name-vade.md)

## License
All rights reserved. Source code is a professional portfolio project.

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
  <img src="https://img.shields.io/badge/License-Proprietary-red">
</p>

<br>

---

## 📱 Screenshots

<table>
  <tr>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding1.png" width="140" alt="Onboarding 1"><br>
      <sub>Welcome</sub>
    </td>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding2.png" width="140" alt="Onboarding 2"><br>
      <sub>Track</sub>
    </td>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding3.png" width="140" alt="Onboarding 3"><br>
      <sub>Currencies</sub>
    </td>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/onboarding4.png" width="140" alt="Onboarding 4"><br>
      <sub>iCloud Sync</sub>
    </td>
  </tr>
</table>

<table>
  <tr>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/dashboard.png" width="140" alt="Dashboard"><br>
      <sub>Dashboard</sub>
    </td>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/quickAdd.png" width="140" alt="Quick Add"><br>
      <sub>Quick Add</sub>
    </td>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/addPerson.png" width="140" alt="Add Person"><br>
      <sub>Add Person</sub>
    </td>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/people.png" width="140" alt="People List"><br>
      <sub>People</sub>
    </td>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/statistics.png" width="140" alt="Statistics"><br>
      <sub>Statistics</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/exchangeRates.png" width="140" alt="Exchange Rates"><br>
      <sub>Exchange Rates</sub>
    </td>
    <td align="center" width="20%">
      <img src="https://github.com/burak-bilgen/Vade/blob/main/screenshots/settings.png" width="140" alt="Settings"><br>
      <sub>Settings</sub>
    </td>
  </tr>
</table>

---

## ✨ Features

| | |
|---|---|
| 💰 **Multi-Currency** | TRY, USD, EUR, and physical gold types (Gram, Quarter, Half, Full, Republic) |
| 🔄 **iCloud Sync** | SwiftData + CloudKit — no backend, just your iCloud |
| 📊 **Live Rates** | Real-time exchange rates from TCMB with offline caching |
| 🏅 **Physical Gold** | Auto-converts gram prices to Çeyrek, Yarım, Tam, Cumhuriyet |
| 📅 **Due Reminders** | Local notifications for upcoming and overdue debts |
| 🔐 **Privacy First** | Face ID / Touch ID app lock with background blur |
| 📄 **Export** | CSV and PDF export of all your data |
| 📱 **Widget** | Home screen widget showing your net balance |
| 🌙 **Dark Mode** | Premium dark-only design, built for finance |
| 🌐 **Bilingual** | Turkish & English |
| ♿ **Accessible** | VoiceOver & Dynamic Type support |
| 📝 **Audit Trail** | Append-only log for every change |

---

## 🏗 Architecture

**iOS 18+ · Swift 6 · Strict Concurrency** — complete data-race safety at compile time.

### MVVM-C (View-First)

Views trust SwiftUI's natural lifecycle. View models handle business logic and state. Coordinator pattern covers navigation where `NavigationStack` falls short.

```
Feature/                     # SPM package per feature
├── Sources/
│   ├── SomeFeatureView.swift
│   ├── SomeFeatureViewModel.swift
│   └── ...
├── Tests/
└── Package.swift
```

**12 SPM packages** — incremental builds. Change one feature, only that package recompiles.

### SwiftData + CloudKit

| Layer | Technology |
|-------|-----------|
| Local DB | SwiftData (`@Model`) |
| Cloud Sync | CloudKit Private Database |
| Conflict Resolution | Append-only audit log + merge policy |
| Offline | Works fully offline, syncs on reconnect |

### Domain / Data Separation

```
Domain/                      # Pure Swift, no UIKit/SwiftUI
├── DebtRecord.swift
├── CurrencyKind.swift
├── Protocols/               # UseCase interfaces
└── ...

Data/                        # SwiftData implementation
├── RepositoryImplementations.swift
├── Models/                  # @Model classes
└── ...
```

### Design System

In-house component library in `DesignSystem` package:

- **ColorTokens**: Dark-only financial palette
- **Typography**: System font + Jakarta Sans, enum-based type scale
- **Components**: `GlassCard`, `PremiumBalanceCard`, `StatCard`, `RateTile`, `ActionPill`, and more
- **FinanceBackgroundAnimation**: Canvas-based animated background

### Networking

`ExchangeRateClient` parses TCMB XML with a 30-minute cache. Offline? Shows cached data. Always works.

### Physical Gold Pricing

| Type | Gram Weight |
|------|-------------|
| Gram Gold | 1.0g |
| Quarter (Çeyrek) | 1.75g |
| Half (Yarım) | 3.5g |
| Full (Tam) | 7.0g |
| Republic (Cumhuriyet) | 7.216g |

API fetches XAU (troy ounce), divides by gram, multiplies by each type's weight.

---

## 🧪 Testing

| Area | Coverage |
|------|----------|
| Domain calculations | 86%+ |
| Repository / Data | 84%+ |
| Networking | 89%+ |
| Analytics events | 100% |
| Snapshots | Native `ImageRenderer`-based (zero deps) |
| ViewModels | Full coverage |

Framework: **Swift Testing** (`@Test`, parameterized). No XCTest.

---

## 🛠 Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| UI | SwiftUI | iOS 18+ |
| Language | Swift 6 | Strict concurrency |
| Architecture | MVVM-C | Testable navigation |
| Database | SwiftData | CloudKit built-in |
| Sync | CloudKit | No backend required |
| Charts | Swift Charts | iOS 16+, native |
| Widget | WidgetKit | iOS 14+ |
| Project Gen | Tuist | No Xcode project in git |
| CI | GitHub Actions | On push & PR |

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

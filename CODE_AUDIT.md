# Vade Code Audit

Generated 2026-07-06. Scope: ~84 Swift files + 6584 LOC across 12 SPM packages (Core, Data, DesignSystem, DIContainer, Domain, FeatureDashboard, FeatureDebtDetail, FeatureOnboarding, FeatureSettings, FeatureWidget, Networking, Observability). `.build/`, `Derived/`, `.claude/skills/` excluded.

Build: zero compiler warnings. SwiftLint: minor import ordering and trailing-comma issues only.

Findings cite `path/to/file.swift:LINE` for Xcode navigation. Each item has recommended action; no code changes made.

---

## 1. Executive summary

Top items to address, in priority order:

1. **[Critical] Widget always shows zero values — data never written to shared UserDefaults** — §5.1 — `VadeWidget.swift:57-61`. Main app never writes `widget.netBalance`/`widget.totalReceivable`/`widget.totalPayable`/`widget.personCount` to App Group UserDefaults. Widget is completely non-functional.
2. **[Critical] Missing App Groups entitlement blocks shared UserDefaults** — §6.1 — `Vade.entitlements:1-17`. No `com.apple.security.application-groups` entry; even if data were written, widget couldn't read it.
3. **[High] Balance calculation ignores payment direction for payable debts** — §5.2 — `RepositoryImplementations.swift:127-130`. Payments always subtracted; payable debts need payments added. Overstates how much user owes.
4. **[High] `nonisolated(unsafe)` NumberFormatter cache accessed without lock during formatting** — §3.1 — `CoreExtensions.swift:14-33`. Lock released before `.string(from:)` call; concurrent threads race on same NumberFormatter instance.
5. **[High] Notification localization broken — `String(localized:)` with string interpolation** — §5.3 — `NotificationService.swift:112-113`. Person name and amount interpolated into key string; will never match localization table entries.
6. **[High] `fatalError` in static URL computed properties** — §5.4 — `ExchangeRateClient.swift:80-90`. URL format change crashes app in production with no recovery.
7. **[High] `@unchecked Sendable` on 11 classes suppresses data-race detection** — §3.2 — 11 locations. Several have only Sendable properties and don't need it; others lack synchronization on mutable state.
8. **[High] Decimal parsing locale mismatch for Turkish users** — §5.5 — `PersonDetailView.swift:187,287` + `ExchangeRateClient.swift:141`. Manual comma-to-period replacement fights locale system; `tr_TR` users get incorrect parse results.
9. **[High] Non-Sendable closures stored in `@unchecked Sendable` class** — §3.3 — `NotificationService.swift:35-51`. Closure properties called from non-isolated async functions can race.
10. **[High] PDF export produces CSV-in-text, not real PDF** — §8.1 — `DataExportService.swift:83-93`. Users get `.pdf` file containing plain text; misleading and broken.

---

## 2. Quick wins (≤30 min each)

- **Add `com.apple.security.application-groups` entitlement** — `Vade.entitlements`. Unblocks widget data sharing. See §6.1.
- **Write widget data from `DashboardViewModel.refreshBalances()`** — `DashboardViewModel.swift:55-57`. Call `UserDefaults(suiteName: "group.com.vade.app")?.set(...)` for netBalance, totalReceivable, totalPayable, personCount after computing balances. Fixes §5.1.
- **Delete `CurrencyChip.swift`** — unused component, 34 lines dead code.
- **Delete `SkeletonView.swift`** — unused skeleton loading components, 129 lines dead code.
- **Remove `@unchecked Sendable` from `KeychainWrapper`** — `SecurityServices.swift:63`. Only stores a `String`; compiler can verify Sendable.
- **Remove `@unchecked Sendable` from `DataExportService`** — `DataExportService.swift:47`. No stored properties; compiler can verify Sendable.
- **Remove `@unchecked Sendable` from `CurrencyConverter`** — `CurrencyConverter.swift:9`. All stored properties are Sendable.
- **Remove `@unchecked Sendable` from `ExchangeRateClient`** — `ExchangeRateClient.swift:157`. All stored properties are Sendable (RatesCache is actor, URLSession is Sendable).
- **Remove `@unchecked Sendable` from `AdService`** — `AdService.swift:20`. Logger and UserDefaults are Sendable.
- **Fix SwiftLint sorted imports** — `AppCoordinator.swift:2-7`, `VadeApp.swift:2-5`. Reorder alphabetically.
- **Fix SwiftLint trailing commas** — `Package.swift` files + `Project.swift`. Remove trailing commas from array/dict literals.
- **Replace `DispatchQueue.main.asyncAfter` with `Task.sleep`** — `UndoToastView.swift:51-55`. Modern concurrency, automatic cancellation.
- **Add `.accessibilityAddTraits(.isButton)` to `onTapGesture`** — `PersonDetailView.swift:88`. VoiceOver won't recognize tappable debt rows as buttons.
- **Fix `String(localized:)` keys with interpolation** — `NotificationService.swift:112-113`. Use `String(localized: "notification.reminder.title \(personName)")` with proper `.xcstrings` format specifiers.

---

## 3. Concurrency

### 3.1 `nonisolated(unsafe)` NumberFormatter cache with unsynchronized formatting access
- **Location:** `Packages/Core/Sources/Core/CoreExtensions.swift:14-33`
- **What:** `NSLock` guards cache dictionary access but `formatter.string(from:)` is called outside the lock on line 15 — after lock released on line 23. Multiple threads can concurrently call `.string(from:)` on the same cached `NumberFormatter` instance.
- **Why:** `NumberFormatter` is not thread-safe. Concurrent use produces undefined behavior — garbled output, crashes, or silent data corruption on formatted currency amounts.
- **Action:** Move `formatter.string(from:)` call inside the lock, or use `OSAllocatedUnfairLock` (iOS 16+, Sendable). Alternative: create a new `NumberFormatter` per call without caching.
- **Severity:** High

### 3.2 `@unchecked Sendable` overuse across 11 classes
- **Locations:**
  - `Packages/Core/Sources/Core/SecurityServices.swift:15` (BiometricAuthService)
  - `Packages/Core/Sources/Core/SecurityServices.swift:63` (KeychainWrapper)
  - `Packages/Core/Sources/Core/NotificationService.swift:32` (NotificationService)
  - `Packages/Core/Sources/Core/MetricKitService.swift:12` (MetricKitService)
  - `Packages/Core/Sources/Core/DataExportService.swift:47` (DataExportService)
  - `Packages/Core/Sources/Core/ScreenProtector.swift:19` (ScreenProtector)
  - `Packages/Networking/Sources/Networking/ExchangeRateClient.swift:157` (ExchangeRateClient)
  - `Packages/Networking/Sources/Networking/CurrencyConverter.swift:9` (CurrencyConverter)
  - `Packages/Observability/Sources/Observability/AdService.swift:20` (AdService)
  - `Packages/Observability/Sources/Observability/AnalyticsService.swift:5` (AnalyticsService)
- **What:** 11 classes suppress Swift 6 sendability checking with `@unchecked Sendable`. Four (KeychainWrapper, DataExportService, CurrencyConverter, AdService) have only Sendable stored properties and don't need it. Two (ExchangeRateClient, BiometricAuthService) use actor-isolated or Sendable-closure state. Two (NotificationService, MetricKitService) extend NSObject. One (AnalyticsService) uses NSLock correctly. One (ScreenProtector) has `@MainActor` work in `Task {}` blocks.
- **Why:** Each `@unchecked Sendable` suppresses compiler data-race detection. A future refactor adding a non-Sendable property goes undetected. For a Swift-6-strict-concurrency project, this undermines the safety guarantee.
- **Action:** See §2 for 5 quick removals. For NSObject subclasses (§3.3, §3.4), keep `@unchecked` but document executor guarantees. For `AnalyticsService`, replace `NSLock` with `OSAllocatedUnfairLock` to go properly Sendable.
- **Severity:** High

### 3.3 Non-Sendable closures stored in `@unchecked Sendable` NotificationService
- **Location:** `Packages/Core/Sources/Core/NotificationService.swift:35-36` (declaration), `:48-51` (implementation), `:86,129` (call sites)
- **What:** `onPermissionRequested: ((Bool) -> Void)?` and `onScheduled: (() -> Void)?` are not `@Sendable`, stored in `@unchecked Sendable` class, called from non-isolated async functions.
- **Why:** Closures can capture non-Sendable values. Called after `UNUserNotificationCenter.requestAuthorization` which resumes on any executor — potential data race.
- **Action:** Change closure types to `@Sendable (Bool) -> Void` and `@Sendable () -> Void`. Audit callers for Sendable-captured state.
- **Severity:** High

### 3.4 Non-Sendable `Container` stored as `@State` in App
- **Location:** `App/Sources/Vade/VadeApp.swift:28`
- **What:** `Container` (DIContainer) is non-Sendable with mutable dictionaries, stored in `@State`.
- **Why:** In practice only accessed from MainActor during init, but compiler doesn't enforce this. Background access would silently race.
- **Action:** Mark `Container` as `@unchecked Sendable` with MainActor-only comment, or annotate all public methods with `@MainActor`.
- **Severity:** Medium

### 3.5 WidgetKit callback-based `TimelineProvider` instead of async variant
- **Location:** `Packages/FeatureWidget/Sources/FeatureWidget/VadeWidget.swift:37-83`
- **What:** Uses `getTimeline(in:completion:)` callback pattern. Async variant `getTimeline(in:) async -> Timeline` available since iOS 16.
- **Why:** Deployment target is iOS 18. Callback pattern complicates concurrency analysis — `AnalyticsService()` created inside nonisolated callback.
- **Action:** Adopt `func getTimeline(in context: Context) async -> Timeline<VadeWidgetEntry>`.
- **Severity:** Medium

### 3.6 Sequential async fetching in ViewModels — missed parallelism
- **Locations:**
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/PeopleListViewModel.swift:76-80`
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardViewModel.swift:46-53`
- **What:** Per-person balance/debt queries execute sequentially in `for` loops with `await` per iteration.
- **Why:** O(n) wall-clock time. For 20+ persons, noticeable loading delay. MainActor-isolated SwiftData ops are fast individually but add up.
- **Action:** Use `withThrowingTaskGroup` for concurrent per-person fetches.
- **Severity:** Medium

### 3.7 Missing `Task.checkCancellation()` in ViewModel loading methods
- **Locations:**
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardViewModel.swift:29-40`
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/PeopleListViewModel.swift:68-86`
  - `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailViewModel.swift:41-50`
- **What:** Async loading methods don't check `Task.isCancelled` or call `try Task.checkCancellation()`.
- **Why:** When SwiftUI view disappears, `.task {}` cancels the task but these methods continue processing. Wasted work, potential stale UI updates.
- **Action:** Add `try Task.checkCancellation()` at method start and at loop iteration tops.
- **Severity:** Low

---

## 4. API modernity

_No findings._ The codebase uses modern Swift 6, SwiftUI, `@Observable`, async/await, and iOS 18 APIs consistently. Zero deprecated API usage detected.

---

## 5. Bugs / logic errors

### 5.1 Widget always shows zero values — main app never writes widget data
- **Location:** `Packages/FeatureWidget/Sources/FeatureWidget/VadeWidget.swift:54-68` (reads), `Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardViewModel.swift:55-57` (computes but never writes)
- **What:** Widget reads `widget.netBalance`, `widget.totalReceivable`, `widget.totalPayable`, `widget.personCount` from `UserDefaults(suiteName: "group.com.vade.app")`. DashboardViewModel computes these values but never writes them to any UserDefaults suite. No code anywhere in the main app calls `set(_:forKey:)` or `setValue(_:forKey:)` for these keys.
- **Why:** Widget renders all-zero values permanently. The widget is completely non-functional — it shows `0.00` for all balances and `0` for person count regardless of actual data.
- **Action:** After DashboardViewModel.refreshBalances() computes totals, write them to `UserDefaults(suiteName: "group.com.vade.app")`. Use String-encoded Decimal to preserve precision. Also call `WidgetCenter.shared.reloadAllTimelines()` to trigger widget refresh.
- **Severity:** Critical

### 5.2 Balance calculation ignores payment direction for payable debts
- **Location:** `Packages/Data/Sources/Data/RepositoryImplementations.swift:127-130` (`execute`), `:138-141` (`netBalance`)
- **What:** `total + signed - record.payments.reduce(Decimal.zero) { $0 + $1.amount }` — payments are always subtracted regardless of debt direction.
- **Why:** For a payable debt of -100 TL with 30 TL payment: `-100 - 30 = -130` (wrong — should be `-100 + 30 = -70`). The user's "how much I owe" total is overstated when partial payments exist on payable debts. Receivable debts are unaffected (correct: `100 - 30 = 70`).
- **Action:** Direction-aware payment adjustment: for `receivable` direction subtract payments, for `payable` direction add payments. Conceptually: `signed + (direction == .receivable ? -paymentTotal : +paymentTotal)`.
- **Severity:** High

### 5.3 Notification localization broken by `String(localized:)` string interpolation
- **Location:** `Packages/Core/Sources/Core/NotificationService.swift:112-113`
- **What:** `content.title = String(localized: "notification.reminder.title \(personName)")` and `content.body = String(localized: "notification.reminder.body \(amount.formatted())")` — person name and formatted amount are interpolated into the localization key string.
- **Why:** The resulting keys become `"notification.reminder.title Ahmet Yılmaz"` and `"notification.reminder.body 1.500,00 TL"` — these will never match entries in the `.xcstrings` catalog. The localized string initializer falls back to the key itself, so users see Turkish text with baked-in names regardless of device language. All 6 supported languages get Turkish notification text.
- **Action:** Use `String(localized: "notification.reminder.title \(personName)")` which Swift 5.9+ treats as format-string localization. Ensure `.xcstrings` has `"notification.reminder.title %@"` and `"notification.reminder.body %@"` entries for all 6 languages.
- **Severity:** High

### 5.4 `fatalError` in static URL computed properties
- **Location:** `Packages/Networking/Sources/Networking/ExchangeRateClient.swift:80-90`
- **What:** `exchangeRatesURL` and `goldRatesURL` are computed properties calling `fatalError()` when `URL(string:)` returns nil for hardcoded URL constants.
- **Why:** Although the URL strings are compile-time constants, `fatalError` crashes the app in production with no recovery path. Static property — crash propagates from any access point (widget refresh, dashboard load, settings).
- **Action:** Store URLs as `static let` constants with `URL(string: ...)!` to crash at launch time (predictable, caught in testing), or use `guard let`/`throw` at each call site for graceful degradation.
- **Severity:** High

### 5.5 Decimal parsing locale mismatch for `tr_TR` users
- **Locations:**
  - `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailView.swift:187`
  - `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailView.swift:287`
- **What:** `Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))` — manual comma-to-period replacement applied regardless of device locale.
- **Why:** In `tr_TR` locale, the decimal separator is comma. User types `"1500,50"` — code replaces comma with period → `"1500.50"`. `Decimal(string:)` in `tr_TR` locale sees period as grouping separator → parses as `150050` or returns nil. Turkish users get wildly incorrect amounts. In `en_US`, user types `"1500.50"` — no comma to replace, parsing works. Bug affects only Turkish-locale devices, which is the primary target market.
- **Action:** Use locale-aware parsing: `Decimal(string: amountText, locale: .current)` with no manual replacement. Or use `NumberFormatter` configured for decimal input to parse user-entered text.
- **Severity:** High

### 5.6 Empty catch blocks silently swallow errors
- **Locations:**
  - `Packages/FeatureOnboarding/Sources/FeatureOnboarding/CloudKitStatusCheck.swift:16`
  - `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailViewModel.swift:47,78,98`
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/PeopleListViewModel.swift:83,93`
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardViewModel.swift:37`
  - `Packages/FeatureSettings/Sources/FeatureSettings/DataManagementView.swift:151,167`
  - `Packages/Data/Sources/Data/AuditTrailService.swift:41,61`
- **What:** All these `catch` blocks only log to OSLog and return nil/false/empty — no user-facing error, no recovery.
- **Why:** SwiftData save failures, CloudKit sync errors, and fetch failures go completely unnoticed by the user. In `DataManagementView`, a partial delete failure corrupts backup state silently. User taps "Add Debt," nothing happens, no error shown.
- **Action:** Surface errors to user via ViewModel `errorMessage` property with alert presentation. At minimum, use `AppLog.*.fault` (not `.info`) for data-loss scenarios. In delete-all path, wrap in transaction.
- **Severity:** Medium

### 5.7 `try?` used in production code without error logging (5 instances)
- **Locations:**
  - `App/Sources/Vade/VadeApp.swift:117` — biometric auth return value silently discarded
  - `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailViewModel.swift:110` — fetch failure returns false
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardViewModel.swift:47,63` — balance/debt fetch failures silently skip
  - `Packages/FeatureSettings/Sources/FeatureSettings/DataManagementView.swift:113,123,175,180` — export/fetch failures return empty
- **What:** `try?` discards the error entirely. Some sites log, others don't.
- **Why:** Silent failure makes data-loading bugs impossible to diagnose. A CloudKit sync issue causing fetch failures is invisible.
- **Action:** Replace `try?` with `do/catch` and log the error. For non-critical paths (export), surface to user. For critical paths (balance fetch), retry or show error state.
- **Severity:** Medium

### 5.8 Widget analytics flag fires on every timeline refresh due to nil UserDefaults
- **Location:** `Packages/FeatureWidget/Sources/FeatureWidget/VadeWidget.swift:72-77`
- **What:** `defaults?.bool(forKey: "widget.hasTrackedAdded") ?? false` — if App Group UserDefaults is nil (missing entitlement), returns false every time. Timeline refreshes hourly → `.widgetAdded` fires every hour.
- **Why:** Analytics data polluted with duplicate widget-added events. Rate-limited Firebase Analytics may throttle the app entirely.
- **Action:** Fix App Groups entitlement first (§6.1). Then use `UserDefaults.standard` as fallback when suite name unavailable.
- **Severity:** Medium

### 5.9 `AnalyticsService.track()` and `CrashlyticsService.recordError()` are no-ops
- **Locations:**
  - `Packages/Observability/Sources/Observability/AnalyticsService.swift:15-19`
  - `Packages/Observability/Sources/Observability/CrashlyticsService.swift:14-16`
- **What:** Both methods only log to OSLog. Neither calls Firebase Analytics or Crashlytics SDKs.
- **Why:** Analytics and crash reporting declared in architecture are not functional. No usage data reaches Firebase. Crashes in production are invisible.
- **Action:** Integrate `Analytics.logEvent(name:parameters:)` and `Crashlytics.crashlytics().record(error:)` calls. If intentionally deferred, add clear `// TODO: Integrate Firebase` markers.
- **Severity:** Medium

### 5.10 CloudKit-ordered relationship arrays may cause sync inconsistency
- **Location:** `Packages/Data/Sources/Data/SwiftDataModels.swift:17-153` (`_payments: [PaymentModel]?`, `_debtRecords: [DebtRecordModel]?`)
- **What:** To-many relationships declared as ordered arrays (`[T]`).
- **Why:** CloudKit does not support ordered to-many relationships. Element ordering is not guaranteed after sync between devices. Could cause data inconsistency.
- **Action:** Use `Set<T>` for CloudKit-safe unordered relationships. Replace indexed access with predicate-based fetches. Document the CloudKit ordering limitation.
- **Severity:** Medium

### 5.11 Two-factor delete confirmation contradicts undo toast UX
- **Location:** `Packages/FeatureSettings/Sources/FeatureSettings/DataManagementView.swift:67-97`
- **What:** Two-alert delete confirmation flow; second alert says "This action cannot be undone" but code immediately provides `UndoToastView` after deletion.
- **Why:** UI message and UX behavior conflict. User sees "cannot be undone" then immediately sees "Undo" button. Confusing and untrustworthy.
- **Action:** Remove second confirmation alert (undo toast suffices), or remove undo toast and keep two-step confirmation as final.
- **Severity:** Low

---

## 6. Security

### 6.1 Missing App Groups entitlement blocks widget data sharing
- **Location:** `Vade/Vade.entitlements:1-17`
- **What:** Entitlements has `aps-environment` (development) and `com.apple.developer.icloud-container-identifiers` but no `com.apple.security.application-groups` entry.
- **Why:** Without this entitlement provisioned and enabled on both main app and widget extension targets, `UserDefaults(suiteName: "group.com.vade.app")` silently returns nil. All widget data sharing is impossible regardless of whether the main app writes data.
- **Action:** Add `com.apple.security.application-groups` with `["group.com.vade.app"]` to entitlements. Enable App Groups capability in both main app and widget extension targets in Xcode.
- **Severity:** Critical

### 6.2 Biometric lock preference stored in UserDefaults plaintext
- **Location:** `Packages/FeatureSettings/Sources/FeatureSettings/SettingsViewModel.swift:21,29`
- **What:** `UserDefaults.standard.bool(forKey: "biometric_enabled")` — biometric lock on/off preference in plaintext.
- **Why:** Malicious actor with device access can write to UserDefaults plist to disable biometric lock without authentication. Keychain-stored flag with `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` would be protected by device passcode.
- **Action:** Store `biometric_enabled` in Keychain using `KeychainWrapper` (already implemented in `SecurityServices.swift`).
- **Severity:** Medium

### 6.3 CSV/PDF export shares PII and financial data with no user warning
- **Location:** `Packages/FeatureSettings/Sources/FeatureSettings/DataManagementView.swift:110-128`, `Packages/Core/Sources/Core/DataExportService.swift:53-74,83-94`
- **What:** Export feature shares person names, amounts, currencies, directions, due dates, and notes via `UIActivityViewController` (share sheet). No confirmation dialog warns about sensitive data.
- **Why:** User can unintentionally AirDrop or message their entire debt portfolio to unintended recipients. Significant privacy implication for a financial app.
- **Action:** Add explicit warning alert before share sheet: "This export contains all your financial records including names and amounts. Only share with trusted recipients." Optionally add anonymized export mode.
- **Severity:** Medium

### 6.4 AnalyticsService tracks PII-adjacent data via OSLog
- **Location:** `Packages/Observability/Sources/Observability/AnalyticsService.swift:18`
- **What:** `AppLog.general.info("[Analytics] \(name) params: \(parameters?.description ?? "nil")")` — analytics event names and parameters (including currency codes, export formats) logged at `.info` level.
- **Why:** If OSLog is collected in production (e.g., via feedback reports), analytics parameters could leak user behavior patterns.
- **Action:** Ensure AppLog is only active in debug builds via `#if DEBUG` guard, or log only event names (not parameters) in production.
- **Severity:** Low

---

## 7. Performance

### 7.1 Views recompute `Decimal.formatted()` on every render
- **Locations:**
  - `Packages/DesignSystem/Sources/DesignSystem/SummaryCard.swift:29,67`
  - `Packages/DesignSystem/Sources/DesignSystem/LedgerRowView.swift:41,66`
  - `Packages/DesignSystem/Sources/DesignSystem/StatChip.swift:19`
  - `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailView.swift:62,138,297`
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardView.swift:22,115`
  - `Packages/FeatureWidget/Sources/FeatureWidget/VadeWidget.swift:102,110,114`
- **What:** `.formatted()` called inline in SwiftUI view bodies. Each call acquires NSLock, looks up cached `NumberFormatter`, bridges to `NSDecimalNumber`, calls `formatter.string(from:)`.
- **Why:** SwiftUI re-renders views frequently. Lock + formatter overhead on every render pass — dozens of times per frame in lists. The `nonisolated(unsafe)` cache also bypasses concurrency safety (§3.1).
- **Action:** Pre-compute formatted strings in ViewModel and cache alongside raw Decimal values. Or compute once via `let formatted = amount.formatted()` in view body before use.
- **Severity:** Medium

### 7.2 Sequential per-person balance fetches scale linearly
- **Location:** `Packages/FeatureDashboard/Sources/FeatureDashboard/PeopleListViewModel.swift:76-80`
- **What:** `for person in persons { balances[id] = try await balanceRepo.execute(...); debts = try await debtRepo.execute(...) }` — awaits each person sequentially.
- **Why:** For 20 persons: 40 sequential SwiftData queries. With CloudKit sync, each query may trigger a round-trip. Total load time grows linearly with person count.
- **Action:** Use `withThrowingTaskGroup` for concurrent fetches. All queries are read-only, independent, and safe to parallelize.
- **Severity:** Medium

### 7.3 Missing SwiftData indexes on frequently-queried properties
- **Locations:**
  - `Packages/Data/Sources/Data/SwiftDataModels.swift:60` — `personID` used in `#Predicate { $0.personID == personID }`
  - `Packages/Data/Sources/Data/SwiftDataModels.swift:64` — `statusRawValue` used in `#Predicate { $0.statusRawValue == "pending" }`
- **What:** `DebtRecordModel.personID` and `DebtRecordModel.statusRawValue` used in predicate filters without `@Attribute(.indexed)`.
- **Why:** As data accumulates over years, unindexed predicates degrade to full table scans. Thousands of records become noticeably slow.
- **Action:** Add `@Attribute(.indexed)` to `personID`, `statusRawValue`, and `createdAt` (used for sort ordering).
- **Severity:** Low

### 7.4 `isDebtFullyPaid` creates unnecessary separate fetch
- **Location:** `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailViewModel.swift:105-113`
- **What:** `isDebtFullyPaid` creates fresh `FetchDescriptor<PaymentModel>` and fetches from database, even though caller already holds the in-memory `debts` array.
- **Why:** Wasted database round-trip on every payment. The `DebtRecord` domain model includes `status` — this can be checked in-memory.
- **Action:** Compute payment total from in-memory `DebtRecord.payments` array instead of re-fetching. Or track `totalPaid` on `DebtRecord` domain model.
- **Severity:** Low

---

## 8. SwiftUI / UI

### 8.1 PDF export produces CSV in text file, not real PDF
- **Location:** `Packages/Core/Sources/Core/DataExportService.swift:83-93`
- **What:** `exportAsPDF()` calls `exportAsCSV()` and wraps the CSV string in a text file with `.pdf` extension. Comment says "Full HTML -> PDF rendering will be re-enabled when API stabilizes."
- **Why:** User taps "Export as PDF" and gets a `.pdf` file containing raw CSV text — not a formatted PDF. Misleading and broken UX.
- **Action:** Either implement real PDF rendering via `UIGraphicsPDFRenderer`, rename to indicate current limitation, or remove PDF option until rendering works.
- **Severity:** High

### 8.2 `onTapGesture` on debt rows without accessibility button trait
- **Location:** `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailView.swift:88-92`
- **What:** `debtRow(debt).onTapGesture { ... }` — tappable row for selecting pending debts uses `onTapGesture` without `.accessibilityAddTraits(.isButton)`.
- **Why:** VoiceOver reads the row as static text, not as an interactive element. Users relying on VoiceOver won't know they can tap to record a payment.
- **Action:** Replace with `Button { if debt.status == .pending { selectedDebt = debt } } label: { debtRow(debt) }` or add `.accessibilityAddTraits(.isButton)`.
- **Severity:** Medium

### 8.3 `ForEach` uses `\.offset` as ID — fragile identity
- **Location:** `Packages/FeatureDashboard/Sources/FeatureDashboard/DashboardView.swift:36`
- **What:** `ForEach(Array(vm.upcomingItems.enumerated()), id: \.offset)` — array index used as stable identifier.
- **Why:** When data reorders, inserts, or deletes, SwiftUI identity tracking breaks — wrong animations, state loss, potential crashes. Each upcoming item should use a stable ID (e.g., person ID + debt ID composite).
- **Action:** Add an `Identifiable` conformance or use `id: \.person.id` if persons are unique, or generate a composite `UUID` for each upcoming entry.
- **Severity:** Medium

### 8.4 `@State private var analytics` creates duplicate AnalyticsService per view
- **Locations:**
  - `App/Sources/Vade/VadeApp.swift:30`
  - `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailView.swift:16`
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/PeopleListView.swift:14`
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/ChartsView.swift:30,71`
  - `Packages/FeatureSettings/Sources/FeatureSettings/DataManagementView.swift:23`
- **What:** Each view creates its own `AnalyticsService()` instance via `@State`.
- **Why:** `setOptOut()` in SettingsViewModel only affects the settings view's instance. All other views continue logging events after user opts out. Each navigation push creates a new instance — wasted memory.
- **Action:** Register `AnalyticsService` as singleton in DI container. Inject via `@Environment` or constructor. Views should not own their analytics instance.
- **Severity:** Medium

### 8.5 `DispatchQueue.main.asyncAfter` in UndoToastView instead of Swift concurrency
- **Location:** `Packages/DesignSystem/Sources/DesignSystem/UndoToastView.swift:51-55`
- **What:** 8-second auto-dismiss scheduled with `DispatchQueue.main.asyncAfter` + `DispatchWorkItem` stored in `@State`.
- **Why:** Pre-concurrency pattern. `DispatchWorkItem` is not Sendable. Cancellation only works if view disappears before 8 seconds. Not integrated with SwiftUI task lifecycle.
- **Action:** Replace with `.task { try? await Task.sleep(for: .seconds(8)); onDismiss() }` — automatic cancellation from SwiftUI, no manual work-item management.
- **Severity:** Medium

### 8.6 Toolbar button uses icon-only `Image(systemName:)` without text label
- **Location:** `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailView.swift:111`
- **What:** `Button { showAddDebt = true } label: { Image(systemName: "plus") }` — icon-only button label.
- **Why:** VoiceOver reads "plus" which is unhelpful. The `.accessibilityLabel` on line 113 partially mitigates but standard pattern is `Button("Add Debt", systemImage: "plus")`.
- **Action:** Use `Button(String(localized: "personDetail.addDebt.button"), systemImage: "plus") { showAddDebt = true }` for proper VoiceOver + visual label.
- **Severity:** Low

### 8.7 `RoundedRectangle` used for background fill — inefficient modifier chain
- **Locations:** `PersonDetailView.swift:69-70`, `DashboardView.swift:60-61,80-81`
- **What:** `.background(RoundedRectangle(cornerRadius:).fill(...)).overlay(RoundedRectangle(cornerRadius:).stroke(...))` — creates two `RoundedRectangle` shapes per view.
- **Why:** Double shape rendering on each background. Minor but repeated across multiple rows.
- **Action:** Use `.background(ColorTokens.surface, in: RoundedRectangle(cornerRadius: Radius.lg)).overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(...))` — single RoundedRectangle reused.
- **Severity:** Low

### 8.8 `String(localized:)` with Turkish literal as key — inconsistent with rest of codebase
- **Location:** `App/Sources/Vade/VadeApp.swift:65`
- **What:** `Text(String(localized: "Yükleniyor..."))` — Turkish string literal used as localization key.
- **Why:** Falls back to Turkish text for all users if `.xcstrings` entry is missing. All other keys use dot-notation identifiers (e.g., `"app.error.containerFailed"`).
- **Action:** Replace with proper key `"app.loading"`.
- **Severity:** Low

---

## 9. Dead code / duplication / refactor

### 9.1 Unused components (154 lines dead code total)
- **Locations:**
  - `Packages/DesignSystem/Sources/DesignSystem/CurrencyChip.swift` — 34 lines. Defined, only referenced in own `#Preview`. Dead code.
  - `Packages/DesignSystem/Sources/DesignSystem/SkeletonView.swift` — 129 lines. `SkeletonView`, `SkeletonSummaryCard`, `SkeletonRow`, `.shimmering(active:)` modifier — only referenced in own `#Preview`. Dead code.
  - `Packages/Core/Sources/Core/ScreenProtector.swift:49` — `blockScreenshots(_:)` method defined in protocol, implemented, never called.
- **Action:** Delete files/methods if not planned for use. If planned, add `// TODO` marker with tracking issue.
- **Severity:** Low

### 9.2 Duplicated `ExportFormat` enum across packages
- **Locations:**
  - `Packages/Core/Sources/Core/DataExportService.swift:5` — `public enum ExportFormat: String, Sendable, CaseIterable { case pdf; case csv }`
  - `Packages/Domain/Sources/Domain/AnalyticsEvent.swift:44` — same enum without `CaseIterable`
- **What:** Two identical enum definitions across packages. Core version has `CaseIterable`, Domain version doesn't.
- **Why:** Drift risk — one definition updated without the other breaks callers. Domain is the right home (used by `AnalyticsEvent`).
- **Action:** Move `ExportFormat` to Domain package. Core.DataExportService imports it from Domain. Delete Core definition.
- **Severity:** Medium

### 9.3 Duplicated comma-to-period Decimal parsing
- **Location:** `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailView.swift:187,287`
- **What:** `Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))` — identical expression in `AddDebtSheet` and `RecordPaymentSheet`.
- **Why:** If the locale-aware fix from §5.5 changes, must update in two places.
- **Action:** Extract as `Decimal` extension or shared helper. Fix locale issue simultaneously (§5.5).
- **Severity:** Low

### 9.4 Duplicated gold conversion multipliers
- **Location:** `Packages/Networking/Sources/Networking/CurrencyConverter.swift:26-33`
- **What:** Five `CurrencyKind` cases call `convertGold(amount:gramMultiplier:)` with inline magic numbers: `Decimal(175)/100`, `Decimal(35)/10`, `7`, `Decimal(7216)/1000`.
- **Why:** Scattered gold-gram ratios — change one and must update multiple locations.
- **Action:** Add `var gramEquivalent: Decimal` computed property on `CurrencyKind` enum.
- **Severity:** Low

### 9.5 Oversized file: PersonDetailView.swift (368 lines)
- **Location:** `Packages/FeatureDebtDetail/Sources/FeatureDebtDetail/PersonDetailView.swift` (368 lines)
- **What:** Single file contains `PersonDetailView` (169 lines), `AddDebtSheet` (102 lines), `RecordPaymentSheet` (64 lines), plus preview container.
- **Action:** Extract `AddDebtSheet` and `RecordPaymentSheet` into own files: `AddDebtSheet.swift`, `RecordPaymentSheet.swift`.
- **Severity:** Low

### 9.6 Hardcoded UserDefaults keys (10 keys across 3 packages)
- **Locations:**
  - `Packages/FeatureSettings/Sources/FeatureSettings/SettingsViewModel.swift:21-49` — `"biometric_enabled"`, `"analytics_opt_out"`, `"crashlytics_opt_out"`, `"app_language"`
  - `Packages/FeatureWidget/Sources/FeatureWidget/VadeWidget.swift:58-76` — `"widget.netBalance"`, `"widget.totalReceivable"`, `"widget.totalPayable"`, `"widget.personCount"`, `"widget.hasTrackedAdded"`
  - `Packages/Observability/Sources/Observability/AdService.swift:29` — `"vade.ads.enabled"`
- **What:** 10 stringly-typed UserDefaults keys scattered across 3 packages.
- **Why:** Typo in key = silent bugs. Rename requires grepping all packages. No compiler verification.
- **Action:** Define `enum UserDefaultsKeys` with `static let` properties in Core package. Reference constants everywhere.
- **Severity:** Medium

### 9.7 Hardcoded magic constants
- **Locations:**
  - `Packages/Core/Sources/Core/NotificationService.swift:119` — `date(bySettingHour: 9, ...)` — hardcoded reminder hour
  - `Packages/Networking/Sources/Networking/ExchangeRateClient.swift:160` — `6 * 3600` — cache validity interval
  - `Packages/FeatureDashboard/Sources/FeatureDashboard/ChartsView.swift:101` — `0.01` — minimum chart value kludge
  - `Packages/FeatureSettings/Sources/FeatureSettings/SettingsViewModel.swift:24` — `"tr"` — hardcoded default language
  - `Packages/FeatureSettings/Sources/FeatureSettings/SettingsView.swift:104` — `"https://vade.app/privacy"` — inline URL in view body
- **Action:** Extract as named constants with documentation.
- **Severity:** Low

### 9.8 Redundant `NotificationService` init
- **Location:** `Packages/Core/Sources/Core/NotificationService.swift:38-46`
- **What:** No-argument `init()` duplicates parameterized `init(onPermissionRequested:onScheduled:)` body with nil parameters.
- **Why:** Parameterized init already has nil defaults on lines 48-49. No-arg init is redundant.
- **Action:** Remove the no-argument `init()`.
- **Severity:** Low

### 9.9 Audit trail injected as optional — silent data loss path
- **Location:** `Packages/Data/Sources/Data/RepositoryImplementations.swift:38`
- **What:** `private let auditTrail: AuditTrailRecording?` — mutations silently skip audit when nil.
- **Why:** If DI registration fails, audit trail goes missing with no warning. CloudKit conflict resolution depends on audit trail for debugging.
- **Action:** Inject a no-op AuditTrailRecording conformance (null object pattern) instead of optional.
- **Severity:** Low

---

## 10. Cross-cutting recommendations

1. **Widget data pipeline needs end-to-end wiring.** The widget is architecturally designed but the data bridge (App Groups entitlement + UserDefaults writes + WidgetCenter reload) was never implemented. §5.1 and §6.1 together represent the highest-impact fix in the app — the widget goes from non-functional to functional in ~30 lines of code.

2. **`@unchecked Sendable` audit is a pre-release gate.** For a Swift-6-strict-concurrency project targeting "complete data-race safety" per README, 11 classes suppressing compiler checks is a significant gap. Remove the 5 unnecessary ones immediately (§2); for the remaining 6, document thread-safety invariants. Replace `NSLock` with `OSAllocatedUnfairLock` where applicable.

3. **Error handling needs a user-facing surface.** The pattern of `catch { AppLog.*.info(...); return nil }` across all ViewModels means users never see errors. Add an `errorMessage` property to ViewModels with `.alert()` presentation. Data mutations (save, delete) should show confirmation on success and alert on failure.

4. **Locale-awareness is critical for the Turkish primary market.** The comma-to-period Decimal parsing (§5.5) fights the locale system on the app's primary target market. Use `NumberFormatter` or locale-aware `Decimal(string:locale:)` throughout.

5. **Analytics and Crashlytics integration is placeholder-only.** Both services log to OSLog but never call Firebase SDKs. Either integrate the actual calls or remove the infrastructure to avoid misleading future developers. If deferred, mark clearly with `// TODO: Firebase integration` at each no-op site.

6. **String(localized:) interpolation pattern is fragile.** NotificationService's use of interpolated values in localization keys (§5.3) will silently fail for all 6 supported languages. Audit all `String(localized:)` calls for interpolation in keys. Use format-string approach with proper `.xcstrings` `%@` placeholders.

---

## 11. What was NOT audited

- `.build/`, `Derived/`, `.claude/skills/` directories (build artifacts, tooling).
- Algorithmic correctness of `InstallmentCalculator` logic beyond basic review.
- Build settings, Xcode project structure beyond entitlements file.
- Third-party SPM dependency internals (Firebase, AdMob).
- Test coverage depth — test files were read for context but not deeply reviewed.
- Widget extension target entitlements — only main app entitlements reviewed.
- StoreKit 2 product configuration.
- Localization `.xcstrings` catalog contents — string catalog structure not assessed.
- Metal/GPU code — none present.
- Firebase console configuration (Google Signals, Ad Personalization settings).
- CI/CD pipeline (GitHub Actions) configuration beyond acknowledging it exists.
- Screen protector screenshot-blocking approach relies on undocumented `UITextField.isSecureTextEntry` behavior — not assessed for future iOS compatibility.

---

## 12. Verification

Spot-check pattern: open Xcode, command-click the `path:line` reference — it lands on the cited line. Every Critical/High finding has exact line range.

- **§5.1** — open `VadeWidget.swift`, lines 57-61. Widget reads from `UserDefaults(suiteName: "group.com.vade.app")`. Grep entire codebase for `set(.*widget\.netBalance|widget\.netBalance.*set)` — returns zero results in main app code. Confirmed: main app never writes widget keys.
- **§6.1** — open `Vade.entitlements`, lines 1-17. No `com.apple.security.application-groups` key. Confirmed: missing entitlement.
- **§5.2** — open `RepositoryImplementations.swift`, lines 127-130. `total + signed - record.payments.reduce(...)` always subtracts. Confirmed: direction-agnostic subtraction.
- **§3.1** — open `CoreExtensions.swift`, lines 14-33. Line 15 calls `cachedFormatter(for:).string(from:)` outside lock (lock released at line 23). Confirmed: formatter used after unlock.
- **§5.3** — open `NotificationService.swift`, lines 112-113. Person name and formatted amount interpolated into `String(localized:)` key. Confirmed: key becomes `"notification.reminder.title Ahmet Yılmaz"`.
- **§5.4** — open `ExchangeRateClient.swift`, lines 80-90. `fatalError("Invalid TCMB URL: ...")` and `fatalError("Invalid gold URL: ...")`. Confirmed: production crash path.
- **§5.5** — open `PersonDetailView.swift`, lines 187, 287. `replacingOccurrences(of: ",", with: ".")` before `Decimal(string:)`. Confirmed: locale-agnostic comma replacement.
- **§8.1** — open `DataExportService.swift`, lines 83-93. `exportAsPDF()` calls `exportAsCSV()` and wraps string in text file. Comment confirms: "Full HTML -> PDF rendering will be re-enabled when API stabilizes."

If any finding doesn't reproduce when you visit the line, let me know with the specific reference and I'll re-investigate.

# ADR-006: Firebase Analytics — Type-Safe Event Whitelist

## Status
Accepted

## Context
Firebase Crashlytics is already integrated for crash reporting. Adding Analytics on the same infrastructure is low-cost and provides actionable insights (feature usage, drop-off points). However, this is a debt/credit tracking app — accidentally logging names, amounts, or notes would be a serious privacy violation.

## Decision
Analytics events go through a **closed, type-safe `AnalyticsEvent` enum** (whitelist pattern):

- No free-form `Analytics.logEvent(_:parameters:)` calls exist anywhere in the codebase.
- All events are defined in a single enum file. Adding a new case requires modifying that file and passing code review.
- The `Observability` SPM package is the **only** package that imports Firebase. Feature modules use the `AnalyticsTracking` protocol injected via DI.
- CI enforces: any `import FirebaseAnalytics` or `Analytics.logEvent` outside `Observability/` fails the build.
- `Analytics.setUserID(_:)` is **never called** — all data is anonymous/aggregate.
- Google Signals and ad personalization are disabled for Analytics (separate from AdMob's ATT flow).

## Consequences
- Privacy-safe analytics by construction, not convention.
- Adding a new event requires intentional code review — prevents accidental data leakage.
- Users can opt out via Settings > Privacy with independent toggles for Analytics and Crashlytics.

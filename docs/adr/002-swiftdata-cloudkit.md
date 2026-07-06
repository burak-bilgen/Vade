# ADR-002: SwiftData + CloudKit for Persistence and Sync

## Status
Accepted

## Context
The app needs persistent local storage with optional multi-device synchronization. There is no custom backend server, and no user authentication system. The app stores user-entered debt/credit records that should survive device loss.

## Decision
**SwiftData** is the persistence framework with **CloudKit** as the sync layer.

- SwiftData provides native iOS integration, `@Model` macros, automatic `ModelContainer` management, and `#Predicate` compile-time safety.
- CloudKit provides private database sync without requiring a backend server or user login (uses the device's iCloud account).
- The stack is entirely Apple-native: no third-party database or sync library.

## CloudKit Schema Constraints (Critical)
These constraints are non-negotiable and must be respected from Phase 0 onward:

1. `@Attribute(.unique)` is **FORBIDDEN** — CloudKit does not support unique constraints.
2. Every property must be **optional or have a default value**.
3. Every relationship must be **optional** (use private stored `_items` + public computed `items` pattern).
4. Ordered relationships are **not supported** — use a separate `sortIndex`/date field.
5. Post-production schema changes are **additive only**: no renaming, deleting, or type-changing of existing fields.

## Consequences
- Zero-cost multi-device sync with no backend infrastructure.
- Schema design is constrained upfront; refactors are expensive post-launch.
- The "private optional + public computed" pattern adds minor boilerplate but ensures CloudKit compatibility.

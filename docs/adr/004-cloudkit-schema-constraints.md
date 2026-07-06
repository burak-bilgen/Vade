# ADR-004: CloudKit Schema Constraints and Additive-Only Policy

## Status
Accepted

## Context
CloudKit sync imposes strict schema requirements on SwiftData models. Violating these constraints causes runtime crashes (`ModelContainer` load failure) or silent data loss during sync.

## Decision
All SwiftData models follow these rules from Phase 0:

1. **No `@Attribute(.unique)`** — CloudKit cannot enforce uniqueness across devices.
2. **Every property is optional or has a default value** — non-optional, default-less properties prevent `ModelContainer` loading.
3. **Every relationship is optional** — even `toMany` with an empty array default. Use the pattern:
   ```swift
   private var _payments: [PaymentModel]?
   var payments: [PaymentModel] { _payments ?? [] }
   ```
4. **No ordered relationships** — use `sortIndex: Int` or date-based sorting instead.
5. **Post-production schema changes are additive-only** — once the CloudKit schema is pushed to production, existing entities/attributes cannot be renamed, deleted, or have their types changed. Only new entities/attributes can be added.

## Consequences
- Schema design must be correct from Phase 0 — fixes are expensive post-launch.
- The "private optional + public computed" pattern is the standard accessor for all relationships.
- `sortIndex` fields must be maintained explicitly for ordered data.

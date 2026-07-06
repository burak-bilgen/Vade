# ADR-005: Liquid Glass Visual Language Adoption Strategy

## Status
Accepted

## Context
Starting April 28, 2026, Apple requires all App Store submissions to be built with Xcode 26 / iOS 26 SDK. Apps built with this SDK and running on iOS 26 devices automatically receive Apple's new "Liquid Glass" visual language on standard system components (TabView, NavigationStack, toolbar, sheets).

This directly impacts the Design System's goal of not looking like "another default SwiftUI app."

## Decision
A **hybrid adoption** strategy:

1. **System chrome accepts Liquid Glass** — TabView, NavigationStack toolbar, and sheets use the system default appearance. This provides a free "this app looks current" signal and doesn't fight Apple's HIG direction. The tint color is set to `ink900`/`brass500` rather than system blue.

2. **Custom content components preserve Design System identity** — All custom-drawn components (`LedgerRowView`, `SummaryCard`, charts, `PillButtonStyle`, `CurrencyChip`, `EmptyStateView`) are unaffected by Liquid Glass since they are not system components. These carry the app's full visual identity.

## Consequences
- Users on iOS 26 see Liquid Glass chrome + custom Design System content.
- Users on iOS 18–25 see standard system chrome + the same custom content.
- No need to opt out of Liquid Glass (which may become harder or impossible in future OS versions).
- The Design System investment is concentrated on content components where it has the most impact.

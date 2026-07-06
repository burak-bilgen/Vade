# ADR-007: App Name — "Vade" and Language-Specific Localization

## Status
Accepted

## Context
The app needed a name that is short, memorable, and directly tied to its core function: due date ("vade") tracking for personal debts/credits. Multi-language localization requires the name to work across 6 target languages.

## Decision

### Primary Name
**"Vade"** — Turkish for "due date/maturity." The app's most powerful recurring-use mechanism is the due-date reminder system, so the name and product essence are inherently aligned.

### Brand Wordmark
The Latin "Vade" wordmark is used globally on the app icon and main brand assets — visual identity is consistent across all markets.

### Language-Specific Display Names (CFBundleDisplayName via InfoPlist.strings)

| Language | Display Name | Rationale |
|----------|-------------|-----------|
| Turkish (tr) | **Vade** | Original — native Turkish financial term |
| English (en) | **Vade** | Short, unique, pronounceable — fits the Venmo/Wise/Wave tradition |
| Spanish (es) | **Vade** | Existing word ("small briefcase," root of "vademécum") — positive connotation |
| Mandarin (zh) | **账期 (Zhàngqī)** | Established commercial term for "payment period/due date" |
| Hindi (hi) | **मियाद (Miyaad)** | Common Hindi/Urdu legal/financial term for "due date/term" |
| Arabic (ar) | **أجل (Ajal)** | Classical Arabic term for "appointed term/due date" — same linguistic root as Turkish "vade" |

### Brand Collision Note
"Vade" is also used by a France-based email security company (formerly Vade Secure, now merging under Hornetsecurity brand). Different country, different sector (B2B cybersecurity vs. consumer finance), different trademark class — practical conflict risk is low. A quick trademark check before App Store submission is recommended.

## Consequences
- Professional localization story for interviews — app name adapts to each market.
- Native speaker review (Phase 5) covers name translations as well, since they are too critical to trust to AI alone.
- Bundle ID (`com.<developer>.vade`) and App Store URL slug remain "vade" globally.

# ADR-003: No Certificate Pinning

## Status
Accepted

## Context
The initial draft included certificate pinning for "bank-level security." This was re-evaluated against the app's actual data flows.

## Decision
**Certificate pinning is NOT implemented.** Standard ATS/TLS validation (system trust store, no `Info.plist` exceptions) is sufficient.

### Rationale
- The app has **no custom backend**. The only outbound network calls are to:
  - TCMB public exchange rate API (anonymous, read-only data)
  - Third-party gold price API (anonymous, read-only data)
- CloudKit traffic is managed by Apple's SDK — app code cannot intercept or pin it.
- Firebase Crashlytics and AdMob networking is abstracted within their SDKs.
- Pinning the public exchange rate API creates a real risk: if the service rotates its certificate (beyond our control), **all users** experience a breakage. The protected data (exchange rates) is not sensitive, making the risk/reward ratio negative.

## Consequences
- No certificate rotation breakage risk.
- Simpler networking layer, easier to maintain.
- This is a deliberate engineering decision — documented for interview discussion. "I considered pinning, evaluated the threat model, and deliberately chose not to" is stronger than "I enabled it because it's a checkbox."

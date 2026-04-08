# KeepTrack — Test Plan

## Test Architecture

| Layer | Tool | Location | CI Job | Required? |
|-------|------|----------|--------|-----------|
| Type Check | tsc | `tsconfig.json` | `ci.yml` → Type Check | Yes |
| Build | next build | — | `ci.yml` → Build | Yes |
| Swift Unit | XCTest | `KeepTrackTests/` | — (needs macOS runner) | Deferred |
| Swift UI | XCUITest | — | — | Deferred |

## Test Inventory

**Web (Next.js):** 0 tests — landing page only, no API routes yet.

**iOS (Swift/Xcode):** XCTest target exists at `KeepTrackTests/` but no CI runner configured (requires `macos-latest` which costs $0.08/min on GitHub Actions).

## Coverage Gaps

- [ ] Web: add vitest + basic route tests when API routes are added
- [ ] iOS: configure macOS CI runner when Apple Developer account is active
- [ ] iOS: unit tests for Core Data models
- [ ] iOS: UI tests for receipt OCR flow
- [ ] iOS: StoreKit 2 sandbox tests (requires TestFlight)

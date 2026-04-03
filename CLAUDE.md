# KeepTrack — Claude Code Instructions

> Part of FOUNDRY (Axiom). Shared rules in ~/Projects/axiom/CLAUDE.md

## Product
- **What:** Warranty & Return Tracker — scan receipts, track return windows and warranty expirations
- **Target:** All consumers (universal need)
- **Stack:** Swift + SwiftUI, Core Data + iCloud, Vision framework (OCR), StoreKit 2
- **Reuses:** VAULT (ReceiptSnap) OCR patterns

## Architecture
- Native iOS (no React Native, no Expo)
- Offline-first with iCloud sync
- Vision framework for OCR (built into iOS — no external API needed)
- Return policy DB: local JSON, updated via remote config
- StoreKit 2 for IAP (shared wrapper from axiom repo)

## PDLC Stage: S2 DEFINE
Current work: MRD → PRD → VAULT OCR reuse assessment

## P0 Features (MVP)
1. Receipt photo capture with OCR extraction (store, date, items, total)
2. Return policy lookup (auto-match store → deadline → countdown)
3. Push notification before return deadline
4. Warranty tracker (major purchases — set expiration date)
5. Searchable purchase archive with photos
6. Export to CSV/PDF

## QA Gate
```bash
xcodebuild test -scheme KeepTrack -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
swiftlint
```

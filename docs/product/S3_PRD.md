# KeepTrack — Product Requirements Document

**Stage:** S2 DEFINE
**Date:** 2026-04-06
**Stack:** Swift + SwiftUI, Core Data + iCloud, Vision (OCR), StoreKit 2

---

## Problem Statement

Consumers lose money every year because they:
- Miss return windows (most are 15–90 days, easy to forget)
- Don't know what their warranty covers or when it expires
- Can't find receipts when they need them most
- Have no reminder system tied to their actual purchase dates

There is no simple, offline-first iOS app that captures receipts via camera, tracks return deadlines and warranty expirations, and proactively reminds users before those windows close.

---

## User Personas

### 1. Busy Parent — "Sam"
- Age: 34, household of 4
- Buys electronics, appliances, kids' gear
- Pain: bought a broken toy, missed the 30-day return, ate the cost
- Goal: never miss a return window again; wants push reminders 5 days before deadline
- Tech comfort: moderate — uses iPhone daily, avoids complex apps

### 2. Online Shopper — "Priya"
- Age: 28, heavy Amazon/Target/Costco buyer
- Pain: juggling 5–10 active orders at any time, loses track of what arrived and when
- Goal: scan receipts at unboxing, set it and forget it
- Tech comfort: high — early adopter, wants fast capture via camera

### 3. Deal Hunter — "Marcus"
- Age: 41, buys during sales and returns if a better deal appears
- Pain: misses price-match and return windows; forgets warranty registration deadlines
- Goal: track item-level return and warranty dates, especially for big-ticket purchases
- Tech comfort: moderate — uses apps for budgeting, open to new tools if they're focused

---

## Core Jobs to Be Done

| # | Job | Acceptance Criteria |
|---|-----|---------------------|
| 1 | **Capture receipt** | User photographs receipt or PDF; OCR extracts store, date, items, total; data pre-fills form in <5s |
| 2 | **Track deadline** | System creates return and warranty countdown for each item; visible on home screen with days remaining |
| 3 | **Get reminded** | Push notification sent at configurable intervals (7d, 3d, 1d) before each deadline |
| 4 | **Archive** | Expired/returned items move to archive; receipt image and data retained indefinitely; searchable |

---

## Scope (S4 MVP)

### In Scope
- Receipt capture via camera + OCR (Vision framework)
- Manual item entry (fallback)
- Return deadline tracking per item
- Extended warranty tracking per item
- Push notifications for upcoming deadlines
- Store library with pre-seeded return policies (top 20 US retailers)
- iCloud sync across user's devices (NSPersistentCloudKitContainer)
- Archive screen for expired items
- Free tier: up to 10 active items
- Pro tier ($2.99/mo or $14.99/yr): unlimited items + bulk export

### Out of Scope (post-MVP)
- Web app
- Shared household accounts (multi-user)
- Email receipt parsing
- Barcode scan for product lookup
- Price-match tracking

---

## Monetization

| Tier | Price | Limits |
|------|-------|--------|
| Free | $0 | 10 active items, no export |
| Pro | $2.99/mo or $14.99/yr | Unlimited items, CSV/PDF export |

StoreKit 2 for IAP. No ads.

---

## Success Metrics (S5 target)

- D7 retention ≥ 40%
- Avg items tracked per active user ≥ 5
- Receipt capture success rate (OCR) ≥ 70%
- Pro conversion rate ≥ 8% within 30 days

---

## Risks

| Risk | Mitigation |
|------|------------|
| OCR accuracy varies by receipt quality | Manual entry fallback; confirmation step before saving |
| iCloud sync conflicts | Server-wins LWW policy; show last-synced timestamp |
| Notification permission denied | In-app prompt with value explanation; graceful degradation |
| App Store rejection for IAP | Follow StoreKit 2 guidelines; no mention of external payment |

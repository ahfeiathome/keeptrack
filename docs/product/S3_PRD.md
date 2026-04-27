# KeepTrack — Product Requirements Document

**Stage:** S5 HARDEN
**Date:** 2026-04-13 (v2 — SubCheck merger integrated)
**Stack:** Swift + SwiftUI, Core Data + iCloud, Vision (OCR), StoreKit 2
**Note:** This PRD supersedes v1 (2026-04-06). Lane 3 (Subscription Audit) was absorbed from SubCheck on 2026-04-09. SubCheck is archived.

---

## Problem Statement

Consumers lose money in three ways they can't easily track:

1. **Missed return windows** — bought something, didn't return in time, lost $50+
2. **Forgotten warranties** — appliance breaks two months after warranty expired
3. **Subscription waste** — paying $219/mo across 8+ subscriptions but only using half

No single iOS app covers all three. Warranty trackers (TrackWarranty, Valid) ignore subscriptions. Subscription auditors (Bobby, ReSubs) ignore purchases. The result: people use 2–3 apps or (more commonly) nothing — and lose money.

**SubCheck merger rationale:** SubCheck was planned as a standalone subscription auditor, but the market is crowded (Rocket Money, Bobby, ReSubs, Pine AI) and its core feature (Apple subscription scan) is technically impossible — StoreKit 2 only reads YOUR app's subscriptions, not all device subscriptions. Absorbing subscription tracking into KeepTrack creates a single app with a data moat no competitor in either market has.

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

### 4. The Over-Subscriber — "Jordan"
- Age: 30, signed up for 3 streaming trials during a slow month, forgot to cancel
- Pain: paying for 9 subscriptions, actively using 4, doesn't know the waste adds up to $80/mo
- Goal: see monthly burn in one screen, cancel unused services without Googling how
- Tech comfort: high — but overwhelmed by financial apps that want bank access
- Key constraint: **will not connect bank account** — privacy concern

---

## Core Jobs to Be Done

| # | Job | Acceptance Criteria |
|---|-----|---------------------|
| 1 | **Capture receipt** | User photographs receipt or PDF; OCR extracts store, date, items, total; data pre-fills form in <5s |
| 2 | **Track deadline** | System creates return and warranty countdown for each item; visible on home screen with days remaining |
| 3 | **Get reminded** | Push notification sent at configurable intervals (7d, 3d, 1d) before each deadline |
| 4 | **Archive** | Expired/returned items move to archive; receipt image and data retained indefinitely; searchable |
| 5 | **Audit subscriptions** | User manually enters subscriptions; app calculates monthly burn rate, categorizes by type, surfaces waste score for services unused 30+ days — no bank connection required |
| 6 | **Get cancel guidance** | User taps any subscription → sees step-by-step cancel instructions specific to that provider → taps deep link to provider's cancellation page |

---

## Feature Lanes

### Lane 1: Return Deadlines (P0 — built)
- OCR receipt scan → auto-detect retailer → pull return policy from library
- Countdown per item on home screen
- Push reminders: 7d, 3d, 1d before deadline
- Return policy library: top 20 US retailers pre-seeded; expandable to 200+
- Manual entry fallback when OCR cannot parse

### Lane 2: Warranty Tracking (P0 — partial)
- Manual entry or OCR-assisted warranty period detection by product category
- Multi-stage alerts: 90d, 30d, 7d before expiry
- Claim guide: step-by-step when warranty is about to expire
- **Open gap:** DatePicker missing in CaptureSheet UI — must be fixed before TestFlight

### Lane 3: Subscription Audit (P1 — not yet built, KT-013 through KT-018)
- **KT-013:** Manual subscription entry with logo + category auto-detection (streaming, productivity, fitness, news)
- **KT-014:** Monthly/annual burn dashboard with category breakdown
- **KT-015:** Waste score — flags subscriptions unused in 30+ days; score 0–100
- **KT-016:** Cancel guides — step-by-step instructions for top 50 services with deep link to cancellation page
- **KT-017:** Trial expiration reminders — push before trial auto-renews
- **KT-018:** Category breakdown view — streaming, productivity, fitness, news
- Privacy-first: **no bank connection, no email scan** — manual entry only
- Monthly burn summary visible on home screen

### All Lanes Share
- Single OCR input (snap receipt → app detects type: purchase/warranty/subscription)
- iCloud sync (NSPersistentCloudKitContainer)
- Push notification system
- Unified savings dashboard — total money saved across all three lanes

---

## Scope (S5 HARDEN)

### In Scope
- Receipt capture via camera + OCR (Vision framework)
- Manual item entry (fallback for all three lanes)
- Return deadline tracking per item with store policy library (200+ retailers target)
- Warranty tracking per item with multi-stage alerts
- **Subscription manual entry with logo/category auto-detection (Lane 3)**
- **Waste score calculation (Lane 3)**
- **Cancel guide content for top 50 subscription services (Lane 3)**
- **Monthly subscription burn summary on home screen (Lane 3)**
- Push notifications for all deadlines and trials
- iCloud sync across user's devices
- Archive screen for expired/returned/cancelled items
- **Onboarding flow — 3-screen walkthrough (KT-019)**
- **Today Widget — next expiring item via WidgetKit (KT-020)**
- Free tier: up to 10 items (any type across all three lanes)
- Pro tier: $3.99/mo — unlimited items, waste score, cancel guides, export, smart insights

### Out of Scope (post-launch)
- Web app
- Shared household accounts (multi-user)
- Email receipt parsing
- Barcode scan for product lookup
- Bank account / financial account connection
- Price-match tracking
- Localization (defer to post-launch P2)

---

## Monetization

| Tier | Price | What's Included |
|------|-------|-----------------|
| Free | $0 | Up to 10 active items across all three lanes; core capture + tracking |
| Pro | $3.99/mo | Unlimited items, waste score, cancel guides, smart insights, CSV/PDF export |
| Annual | TBD | To be set before App Store submission |

**Price decision:** $3.99/mo confirmed by Michael (2026-04-13). Higher than original $2.99 because value proposition covers three lanes, not just warranties. Annual pricing TBD — set before App Store submission.

**StoreKit 2:**
- Monthly product ID: `com.bigclaw.keeptrack.pro.monthly`
- Annual product ID: `com.bigclaw.keeptrack.pro.annual` (TBD price)
- Subscription group: `KeepTrack Pro`
- Promotional offers: introductory 7-day free trial (to be confirmed before submission)
- 10-item free limit enforced at Core Data layer, not only in UI
- No ads, no external payment mention

---

## Data Model

Core Data entities. All synced via NSPersistentCloudKitContainer except where noted.

| Entity | Key Attributes | Notes |
|--------|---------------|-------|
| `Item` | id, name, purchaseDate, storeId, notes, laneType (return/warranty/subscription), isArchived | Base entity shared across lanes |
| `Receipt` | id, itemId, photoURL (local cache), ocrRawText, capturedAt | Photo stored locally; URL is local path |
| `ReturnDeadline` | itemId, windowDays, deadlineDate, returnedAt | Computed from purchaseDate + store policy |
| `Warranty` | itemId, expiresAt, coverageNotes, claimUrl | Manual or auto-detected by category |
| `Store` | id, name, logoUrl, returnWindowDays, receiptRequired, exceptions, restockingFee, lastUpdated | Local JSON; remote config update quarterly |
| `Subscription` | id, name, logoUrl, category, priceMonthly, billingCycle, startDate, lastOpenedAt, cancelUrl, cancelGuide, trialEndsAt | Lane 3 entity; no bank data |
| `Notification` | itemId, fireAt, type (deadline7d/3d/1d/wasteAlert), delivered | UNUserNotificationCenter scheduling |

---

## Screen Inventory

| Screen | Purpose | Lane |
|--------|---------|------|
| **Home** | Items expiring soonest (return + warranty) + subscription waste alerts; unified savings total | All |
| **Capture** | Camera + OCR flow → type detection → form pre-fill | 1, 2 |
| **Item Detail** | Return countdown, receipt photo, warranty info, edit | 1, 2 |
| **Subscription List** | All subscriptions, monthly burn total, category breakdown | 3 |
| **Waste Score** | Subscriptions flagged unused 30+ days; score 0–100; cancel CTA per item | 3 |
| **Cancel Guide** | Step-by-step cancel instructions + deep link for a specific subscription | 3 |
| **Archive** | All expired/returned/cancelled items; searchable; filterable by lane | All |
| **Settings** | Pro upgrade, notification preferences, export, iCloud sync status, store policy version | All |
| **Onboarding** | 3-screen walkthrough: three lanes → permissions → first item wizard | All |
| **Today Widget** | WidgetKit: next expiring return, warranty, or trial | All |

---

## Accessibility

- **VoiceOver:** All interactive elements have `accessibilityLabel` and `accessibilityHint`. Countdown timers use `accessibilityValue` ("3 days remaining"). Buttons with icon-only display have explicit labels.
- **Dynamic Type:** All text uses SwiftUI `Font.body`, `.caption`, etc. — scales with system font size. No fixed point sizes for body copy. Test at largest accessibility size.
- **Tap targets:** Minimum 44×44pt for all buttons and interactive elements.
- **Color independence:** Status indicators (waste score, countdown urgency) use both color AND icon/text. Never color alone. Example: expiring items are both red AND show a warning icon.
- **Contrast:** All text meets WCAG 2.1 AA (4.5:1 body, 3:1 large text). Test with Simulator Accessibility Inspector.
- **Reduced Motion:** Animations respect `UIAccessibility.isReduceMotionEnabled`.
- **Dark mode:** Full support required before TestFlight. Core Data-bound UI components auto-adapt; custom colors use semantic Color assets.

---

## Store Policy Library

**Current state:** 30 retailers in `stores.json` (local bundle)
**Target:** 200+ retailers before App Store submission

**Data sources:**
- Primary: retailer websites (return policy pages)
- Secondary: ReturnPolicy.com, consumer forums
- Each entry: return window (days), receipt required (bool), exceptions (free-text), restocking fee (%), exchange-only categories

**Update cadence:**
- Quarterly review by lc-axiom — check top-50 retailers for policy changes
- Remote config endpoint (URL TBD) allows policy updates without App Store release
- User reporting: "Report wrong policy" link on Store Detail screen → submits to ops/POLICY_REPORTS.md for next quarterly pass

---

## Success Metrics (S5–S6 targets)

| Metric | Target | Timeline |
|--------|--------|----------|
| D7 retention | ≥ 40% | Post-TestFlight |
| Avg items tracked per user | ≥ 5 | 30 days |
| OCR capture success rate | ≥ 85% | 30 days (Apple Vision Framework on printed receipts; 70% was a conservative pre-build estimate) |
| Pro conversion rate | ≥ 8% | 30 days |
| Subscription tracking adoption (Lane 3) | ≥ 30% of active users | 90 days |
| Avg subscriptions tracked per user | ≥ 3 | 90 days |
| Waste score engagement | ≥ 50% of subscription users view waste score | 90 days |
| Avg savings identified per user | $50+/month | 90 days |

---

## Risks

| Risk | Mitigation |
|------|------------|
| OCR accuracy varies by receipt quality | Manual entry fallback; confirmation step before saving; target 85% (Vision framework on printed receipts) |
| iCloud sync conflicts | Server-wins LWW policy; show last-synced timestamp in Settings |
| Notification permission denied | In-app prompt with value explanation ("We'll remind you 5 days before your Costco return window closes"); graceful degradation |
| App Store rejection for IAP | Follow StoreKit 2 guidelines strictly; no mention of external payment options in app |
| Lane 3 not differentiated without cancel guide content | Cancel guide DB for top 50 services is a one-time content asset; maintain in `subscriptions.json` bundle, updateable via remote config |
| Store policy data goes stale | Quarterly review process + user reporting ("Report wrong policy") creates feedback loop |
| Apple Developer account ($99) blocks TestFlight | This is the first blocker before anything ships; escalated to Michael (💳 gate) |

---

## Open PRD Items (to add before TestFlight)

| ID | Item | Status |
|----|------|--------|
| KT-013 | Manual subscription entry + logo auto-detect | P1, not built |
| KT-014 | Monthly burn dashboard + category breakdown | P1, not built |
| KT-015 | Waste score calculation | P1, not built |
| KT-016 | Cancel guides for top 50 services | P1, not built |
| KT-017 | Trial expiration reminders | P1, not built |
| KT-018 | Category breakdown view | P1, not built |
| KT-019 | Onboarding flow (3-screen walkthrough) | P1, not built |
| KT-020 | Today Widget (WidgetKit) | P2, not built |
| KT-021 | Design polish (dark mode, haptics, animations) | P2, partial |
| — | DatePicker in CaptureSheet (Lane 2 gap) | Bug, must fix before TestFlight |
| — | App Store assets (icon, screenshots, description) | Placeholder — needs Lane 3 UI first |

# KeepTrack — S2 Market Requirements Document

**Date:** 2026-04-08
**Author:** Consultant (Claude Chat)
**Product:** KeepTrack — Receipt & Warranty Tracker (iOS)

---

## 1. Problem Statement

Consumers miss return windows and forget warranty expiration dates because they have no system to track them. The average household makes 50+ returnable purchases per year. Missing even one 30-day return window on a $50 item costs real money. No simple, offline-first iOS app captures receipts via camera, tracks deadlines, and sends proactive reminders.

## 2. Market

**TAM:** 150M US smartphone users who make regular purchases
**SAM:** iOS users who return items or track warranties — ~30M
**SOM (12-month):** 500-2,000 users via App Store organic + ASO

## 3. Customer

**Primary: The Organized Buyer** — tracks purchases, hates missing return windows. Wants push reminders. Uses iPhone daily. Moderate tech comfort.

**Secondary: The Deal Hunter** — buys during sales, returns if better deal appears. Needs item-level deadline tracking.

## 4. Competition

| Competitor | Price | Threat | Our edge |
|-----------|-------|--------|----------|
| Bobby | $1.99 one-time | 🟡 Medium (iOS, inactive dev) | Active development, OCR capture |
| ReSubs | Freemium | 🟡 Medium (subscription focused) | We're receipt/warranty, not subscriptions |
| Rocket Money | $7-14/mo | 🟢 Low (bank-connected, expensive) | Privacy-first, no bank access needed |
| Apple Notes scanner | Free | 🔴 High (free, pre-installed) | Deadline tracking + reminders — Notes can't do this |

## 5. Pricing

- Free: 10 active items
- Pro: $2.99/mo or $14.99/yr — unlimited items + export (StoreKit 2 IAP)

## 6. Success Metrics (post-TestFlight)

| Metric | Target |
|--------|--------|
| D7 retention | ≥40% |
| Avg items tracked/user | ≥5 |
| OCR capture success rate | ≥70% |
| Pro conversion within 30 days | ≥8% |

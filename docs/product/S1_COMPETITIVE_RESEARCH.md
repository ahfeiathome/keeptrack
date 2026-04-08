# KeepTrack — S1 Competitive Research

**Status:** COMPLETE
**Date:** 2026-04-07
**Author:** Consultant (Claude Chat)
**Product:** KeepTrack — Warranty & Return Tracker

---

## Market Overview

The consumer warranty tracking space is fragmented and underserved. Most solutions are either enterprise warranty management platforms (Tavant, Mize, InsightPro — irrelevant to us) or small indie apps with poor UX. No dominant consumer-grade iOS app exists. The pain point is real: the average household loses $1,000+ over a lifetime due to expired warranties and lost receipts.

## Competitive Landscape

| App | Platform | Price | Key Feature | Weakness | Downloads/Rating |
|-----|----------|-------|-------------|----------|-----------------|
| **TrackWarranty** | iOS + Android | Free | AI receipt scanning, Gmail import, expiry alerts | New, small user base | New entrant |
| **Valid (Warranty Receipts)** | iOS | Free (15 items) / Pro IAP | Dashboard, 90/30/7 day alerts, claim tracking, AI advisor | Free tier capped at 15 items | New (iOS 18 required) |
| **Warranty Keeper** | Android + iOS | Free | Simple entry, push notifications, cloud backup | Slow, basic UI | Small |
| **MrReceipt** | Android + iOS | Free | Receipt scan → warranty tracking | No manual entry — receipt-only | Small |
| **MyItems** | iOS + Android | Free | Item documentation, warranty alerts, ownership transfer | Feature-heavy, complex UX | Niche |
| **Garantly** | iOS | Free | PDF upload, reminders, minimal design | Very new (2026), sparse features | Brand new |
| **Home Contents** | iOS | Free | Simple warranty + home inventory | Basic, iOS only | Small |
| **Notion template** | Cross-platform | Free | Customizable database | Requires Notion knowledge, no native alerts | DIY only |
| **Apple Wallet** | iOS | Free | Some receipts/warranties stored | Not purpose-built, limited | Built-in |

## Pricing Benchmarks

| Tier | Market Standard | Our Plan |
|------|----------------|----------|
| Free | 5-15 items, basic alerts | 50 items, basic features |
| Pro | $1.99-4.99 one-time or $2.99-4.99/mo | $3.99/mo Apple IAP |

## Market Gap — GO Signal

**No dominant player exists.** The best-funded apps (TrackWarranty, Valid) are brand new (2026). Most competitors are small indie projects with basic UX and no AI. The market is wide open for a polished, OCR-powered iOS app.

**KeepTrack differentiators:**
1. **OCR receipt scanning** — snap a receipt, auto-extract warranty dates (reuses VAULT OCR work)
2. **iCloud sync** — seamless Apple ecosystem integration
3. **Push notifications** — multi-stage alerts (90, 30, 7 days)
4. **StoreKit 2 Pro tier** — shared FOUNDRY IAP infrastructure
5. **Return deadline tracking** — not just warranties, also return windows

**Risk:** TrackWarranty is pursuing the same AI-receipt-scanning angle with a freemium model. Speed to market matters. KeepTrack already has an archive built — blocked only on Apple Developer $99.

## Verdict: 🟡 OPEN MARKET — Favorable

Not a red ocean (no dominant players) but also not a blue ocean (concept is understood, several small entrants). First polished iOS app with OCR + iCloud + push notifications wins the segment.

## Sources
- techpp.com/2024/05/17/warranty-tracker-apps/
- trackwarranty.app
- apps.apple.com/us/app/warranty-receipts-valid/id6760669094
- apps.apple.com/us/app/garantly-warranty-tracker/id6760946481
- myitems.com

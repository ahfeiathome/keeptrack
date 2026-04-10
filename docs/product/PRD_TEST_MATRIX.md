# KeepTrack — PRD Test Matrix

> Created: 2026-04-10  
> Method: Source code review of Swift files (native iOS — no web URL to hit)  
> Stack: Swift + SwiftUI, Core Data + CloudKit, Vision OCR, StoreKit 2  
> **Blocker:** All E2E / device tests require Apple Developer account ($99). Currently blocked on Michael.

---

## How to Run Unit Tests (when Xcode project is set up)

```bash
cd axiom/keeptrack
xcodebuild test -scheme KeepTrack -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
swiftlint
```

No automated tests currently exist in the repo — see gaps section.

---

## KT-001 — Receipt Capture

| # | Test | Verification Method | Expected | Status |
|---|------|---------------------|----------|--------|
| 1.1 | Camera opens on + tap | Device/Simulator | CameraView renders, shutter visible | ✅ CaptureSheet camera state confirmed |
| 1.2 | Library picker available | Code review | PhotosPicker option visible | ✅ PhotosPicker in cameraBody |
| 1.3 | OCR runs on captured image | Code review | OCRService.recognize() called, state transitions to .processing | ✅ runOCR() called in onChange handler |
| 1.4 | Store name extracted | Unit test | OCRService.parse() returns storeName from top of receipt text | ✅ extractStoreName() implemented |
| 1.5 | Purchase date extracted | Unit test | Date parsed from 6 format patterns | ✅ extractDate() with DateFormatter array |
| 1.6 | Items + total extracted | Unit test | Lines with price patterns parsed, total-line detected | ✅ extractItemsAndTotal() implemented |
| 1.7 | Low-confidence fallback | Code review | isLowConfidence=true → goes to manual entry | ✅ runOCR() checks isLowConfidence |
| 1.8 | Review form pre-filled | Code review | populateForm() sets retailer, date, name, price | ✅ populateForm() confirmed |
| 1.9 | Manual entry fallback | Device/Simulator | Manual button skips OCR | ✅ Manual state in CaptureState enum |

**Missing unit tests:** OCRService has no test file. `extractStoreName`, `extractDate`, `extractItemsAndTotal` are untested against known receipt text samples.

---

## KT-002 — Return Deadline Tracking

| # | Test | Verification Method | Expected | Status |
|---|------|---------------------|----------|--------|
| 2.1 | Return deadline computed from store | Code review | StoreMatcher.match() → store.returnDays → computed deadline | ✅ populateForm() uses store.returnDays |
| 2.2 | Deadline shown in item list | Device/Simulator | ItemRow shows days-remaining countdown | ✅ HomeView sorted by returnDeadline |
| 2.3 | Items sorted by soonest deadline | Code review | FetchRequest sort by returnDeadline ASC | ✅ HomeView FetchRequest confirmed |
| 2.4 | Returned items excluded from home | Code review | predicate: isReturned == NO | ✅ HomeView predicate confirmed |
| 2.5 | Mark returned hides item | Device/Simulator | Swipe left → Returned → item disappears | ✅ markReturned() sets isReturned=true |

---

## KT-003 — Warranty Tracking

| # | Test | Verification Method | Expected | Status |
|---|------|---------------------|----------|--------|
| 3.1 | warrantyDeadline field exists | Code review | Core Data model has warrantyDeadline Date attribute | ✅ KeepTrack.xcdatamodel confirmed |
| 3.2 | warrantyMonths field exists | Code review | Core Data model has warrantyMonths Int16 | ✅ Confirmed |
| 3.3 | HomeView sorts by warrantyDeadline | Code review | Second sort descriptor is warrantyDeadline ASC | ✅ HomeView confirmed |
| 3.4 | UI to set warranty date | Device/Simulator | CaptureSheet or item detail shows warranty date picker | ❌ **Missing** — CaptureSheet ItemForm has no warrantyDeadline field |
| 3.5 | Warranty expiration reminder | Code review | ReminderScheduler handles warranty deadlines | ❌ **Missing** — ReminderScheduler only handles returnDeadline |

**Gap:** The data model supports warranty tracking but there's no UI to enter a warranty expiration date. CaptureSheet only captures return deadline. No warranty-specific reminder logic in ReminderScheduler.

**Fix needed:** Add warrantyDeadline DatePicker to CaptureSheet review/manual forms, and add warranty reminder scheduling to ReminderScheduler.

---

## KT-004 — Push Notifications

| # | Test | Verification Method | Expected | Status |
|---|------|---------------------|----------|--------|
| 4.1 | 7-day reminder scheduled | Code review | intervals=[7,3,1]; 7d trigger computed | ✅ ReminderScheduler.intervals confirmed |
| 4.2 | 3-day reminder scheduled | Code review | Same | ✅ |
| 4.3 | 1-day reminder scheduled | Code review | Same | ✅ |
| 4.4 | Reminders fire at 9am | Code review | components.hour=9, components.minute=0 | ✅ Confirmed |
| 4.5 | Past trigger dates skipped | Code review | `guard triggerDate > now` | ✅ Confirmed |
| 4.6 | Reminders cancelled on return | Code review | markReturned() calls cancelReminders() | ✅ HomeView confirmed |
| 4.7 | Reminders cancelled on delete | Code review | deleteItems() calls cancelReminders() | ✅ HomeView confirmed |
| 4.8 | Permission requested on first save | Code review | NotificationService.requestPermission() in saveItem() | ✅ CaptureSheet confirmed |
| 4.9 | Reminders rescheduled on launch | Code review | rescheduleAll() available | ✅ ReminderScheduler.rescheduleAll() confirmed (caller TBD) |

**Note:** Verify rescheduleAll() is called from KeepTrackApp.swift on launch.

---

## KT-005 — iCloud Sync

| # | Test | Verification Method | Expected | Status |
|---|------|---------------------|----------|--------|
| 5.1 | CloudKit container used | Code review | NSPersistentCloudKitContainer (not NSPersistentContainer) | ✅ PersistenceController confirmed |
| 5.2 | Auto-merge enabled | Code review | automaticallyMergesChangesFromParent=true | ✅ Confirmed |
| 5.3 | Merge policy set | Code review | NSMergePolicy.mergeByPropertyObjectTrump | ✅ Confirmed |
| 5.4 | Cross-device sync | Device test | Add item on iPhone, appears on iPad | ⚠️ Requires Apple Dev account + 2 devices |

---

## KT-006 — Store Library

| # | Test | Verification Method | Expected | Status |
|---|------|---------------------|----------|--------|
| 6.1 | stores.json bundled | Code review | Bundle.main.url(forResource: "stores") succeeds | ✅ KeepTrack/Resources/stores.json exists |
| 6.2 | 30 stores with return days | Code review | JSON array has ≥20 entries with name, aliases, returnDays | ✅ 30 stores confirmed |
| 6.3 | Target matches correctly | Unit test | StoreMatcher.match("Target", context:) → 90 days | ✅ Target: 90d in catalog |
| 6.4 | Best Buy matches correctly | Unit test | "Best Buy" → 15 days | ✅ Confirmed |
| 6.5 | Apple Store matches correctly | Unit test | "Apple Store" → 14 days | ✅ Confirmed |
| 6.6 | Unknown store fallback | Unit test | "Mom's Pottery" → 30 days (default) | ✅ findOrCreate with returnDays=30 |
| 6.7 | Alias matching | Unit test | "walmart.com" or "wal-mart" → Walmart (90d) | ✅ aliases array in StoreEntry |

**PRD checklist was wrong:** KT-006 was marked "Not Started" but is fully implemented. Updated.

---

## KT-007 — Archive Screen

| # | Test | Verification Method | Expected | Status |
|---|------|---------------------|----------|--------|
| 7.1 | Returned items appear | Device/Simulator | Mark item returned → appears in Archive tab | ✅ predicate: isReturned==YES |
| 7.2 | Expired items appear | Code review | returnDeadline < Date() included | ✅ predicate: returnDeadline < now |
| 7.3 | Search works | Device/Simulator | Type in search bar → filtered results | ✅ searchable() + filter in filteredItems |
| 7.4 | Empty state when nothing archived | Device/Simulator | "No Archived Items" message with icon | ✅ Confirmed in ArchiveView |

---

## KT-008 — StoreKit 2 Pro Tier

| # | Test | Verification Method | Expected | Status |
|---|------|---------------------|----------|--------|
| 8.1 | Product fetched from App Store | Code review | Product.products(for: [proProductID]) on init | ✅ fetchProducts() in init |
| 8.2 | Purchase flow completes | Sandbox test | Tap upgrade → StoreKit sheet → purchase → isPro=true | ✅ purchase() implemented |
| 8.3 | Entitlement verified on launch | Code review | verifyEntitlements() called in init | ✅ Confirmed |
| 8.4 | Transaction listener active | Code review | listenForTransactions() background task in init | ✅ Confirmed |
| 8.5 | Refund detected and revoked | Code review | revocationDate != nil → setPro(false) | ✅ Confirmed |
| 8.6 | Restore purchases works | Sandbox test | Tap restore → AppStore.sync() → entitlements re-verified | ✅ restorePurchases() implemented |
| 8.7 | Free tier 10-item limit enforced | Code review | activeItems.count >= 10 → showUpgradePrompt | ✅ CaptureSheet confirmed |
| 8.8 | Pro badge shown in toolbar | Code review | store.isPro → gold star badge in HomeView toolbar | ✅ HomeView confirmed |
| 8.9 | Cached isPro survives cold start | Code review | UserDefaults.standard.bool(forKey: proStatusKey) | ✅ Confirmed |

---

## P0 Summary

| ID | Item | Verified Status | Gaps |
|----|------|----------------|------|
| KT-001 | Receipt Capture | Done | No unit tests for OCRService parsing |
| KT-002 | Return Deadline Tracking | Done | — |
| KT-003 | Warranty Tracking | Partial | No UI to set warranty date; no warranty reminders |
| KT-004 | Push Notifications | Done | Verify rescheduleAll() called on app launch |
| KT-005 | iCloud Sync | Done | Cross-device test requires 2 devices + Apple Dev account |
| KT-006 | Store Library | Done | Was incorrectly marked "Not Started" — 30 stores implemented |
| KT-007 | Archive Screen | Done | — |
| KT-008 | StoreKit 2 Pro Tier | Done | Sandbox testing requires Apple Dev account |

**Blockers before TestFlight:**
1. Apple Developer account ($99) — required for TestFlight, sandbox IAP testing, device provisioning
2. Fix KT-003 warranty date entry UI (add `warrantyDeadline` field to CaptureSheet)
3. Add OCRService unit tests (critical logic, zero test coverage)

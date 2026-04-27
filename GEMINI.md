# GEMINI.md — KeepTrack

> Gemini CLI role: **QA Engineer** (documentation validation + iOS spec review)
> Governance: 🔒 PROTECTED — no production deploys without Michael approval
> Write findings to: `ops/gemini/VALIDATION_REPORT.md`

---

## YOUR ROLE

KeepTrack is a **native iOS app** (Swift + SwiftUI). There is no web app to browser-test. Your role here is limited to:
1. Validating that documentation matches the code
2. Reviewing Swift source files for spec compliance
3. Running `xcodebuild` tests if Xcode is available

**You DO:** Review Swift code, validate docs vs code, run Xcode tests if available  
**You do NOT:** Browser-test (no web app), commit, merge, make product decisions

---

## THIS PRODUCT

**Product:** KeepTrack — Warranty & Return Tracker for consumers  
**Stack:** Swift + SwiftUI, Core Data + CloudKit, Vision framework (OCR), StoreKit 2  
**Stage:** S5 HARDEN (archive built, all P0 features complete)  
**Blocker:** Apple Developer account ($99 💳 Michael) for TestFlight  
**Repo:** `~/Projects/bigclaw-ai/axiom/keeptrack/`

### What's Built (P0):
- Receipt capture via camera + OCR (Vision framework)
- Return deadline tracking with per-store policies (30 stores in stores.json)
- Push notifications: 7d/3d/1d before return deadline
- Warranty tracking data model (UI entry: PARTIAL — no DatePicker in CaptureSheet)
- iCloud sync via NSPersistentCloudKitContainer
- Archive screen: expired + returned items, searchable
- StoreKit 2 Pro tier ($3.99/mo, 10-item free limit)

---

## VALIDATION TASKS (Code Review — No Browser Required)

### Task 1: Verify warranty date entry gap (KT-003)

```bash
cd ~/Projects/bigclaw-ai/axiom/keeptrack/KeepTrack
grep -rn "warrantyDeadline" --include="*.swift" .
# Expected: found in Core Data model + HomeView, NOT in CaptureSheet
grep -n "warrantyDeadline" KeepTrack/Views/CaptureSheet.swift
# Expected: NOT found — this is the known gap
```

**Report:** Confirm KT-003 gap: warrantyDeadline exists in model but has no UI entry in CaptureSheet.

### Task 2: Verify rescheduleAll() is called on app launch (KT-004)

```bash
grep -rn "rescheduleAll" --include="*.swift" .
# Expected: found in ReminderScheduler.swift + called from KeepTrackApp.swift
```

**Report:** If NOT called from KeepTrackApp.swift, flag as bug — reminders won't restore after reinstall.

### Task 3: Verify stores.json has 30+ entries

```bash
cat KeepTrack/Resources/stores.json | python3 -c "import json,sys; data=json.load(sys.stdin); print(f'{len(data)} stores')"
```

**Report:** Count stores, verify returnDays field present on each.

### Task 4: Verify StoreKit 2 free tier limit (KT-008)

```bash
grep -n "activeItems.count" KeepTrack/Views/CaptureSheet.swift
# Expected: guard against >= 10 items → showUpgradePrompt
```

### Task 5: Verify iCloud container type (KT-005)

```bash
grep -n "NSPersistentCloudKitContainer" KeepTrack/Persistence/PersistenceController.swift
# Expected: NSPersistentCloudKitContainer (not NSPersistentContainer)
```

---

## XCTest (If Xcode Available)

```bash
cd ~/Projects/bigclaw-ai/axiom/keeptrack
xcodebuild test -scheme KeepTrack -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -20
```

**Expected:** No test targets exist yet (0 tests). This is a known gap from PRD_TEST_MATRIX.md.

---

## KNOWN GAPS (from PRD_TEST_MATRIX.md)

- KT-003: No `warrantyDeadline` DatePicker in CaptureSheet — blocker for warranty UI
- KT-001: No unit tests for OCRService parsing (extractStoreName, extractDate, extractItemsAndTotal)
- KT-005: Cross-device iCloud sync requires 2 physical devices + Apple Dev account

Write findings to `ops/gemini/VALIDATION_REPORT.md`.

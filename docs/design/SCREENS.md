# KeepTrack — Screen Inventory
**Stage:** S3 DESIGN | **Last updated:** 2026-04-06

## Overview
5 primary screens. iPhone-first. iPad stretch goal via adaptive layouts.
Navigation: `NavigationStack` root with `TabView` (Home, Archive, Settings) + modal sheets for Capture and Item Detail.

---

## 1. Home (Dashboard)

**Purpose:** At-a-glance view of all active items sorted by soonest deadline.

**Key UI Elements:**
- Header: "KeepTrack" title + `+` capture button (top-right)
- Items list: `List` sorted ascending by deadline date
  - Each row: item name, retailer, thumbnail, countdown badge ("3 days left" / "Expired")
  - Countdown badge color: green (>7 days), yellow (3–7 days), red (<3 days), gray (expired)
- Empty state: illustration + "Tap + to add your first receipt"
- Badge on tab icon = items expiring within 7 days

**SwiftUI Components:**
- `NavigationStack`
- `TabView` (tab 1)
- `List` with `ForEach` over sorted items
- `.badge()` modifier on `TabItem`
- `Label`, `Image(systemName:)` for icons

---

## 2. Capture (Camera + OCR Flow)

**Purpose:** Add a new item by photographing a receipt or entering details manually.

**Key UI Elements:**
- Full-screen camera view (AVCaptureSession wrapper via `UIViewControllerRepresentable`)
- Shutter button (bottom-center), flip camera, photo library picker
- Post-capture: OCR processing spinner ("Reading your receipt…")
- OCR result review form (pre-filled fields, user can edit):
  - Item name, Retailer, Purchase date, Return deadline, Warranty deadline
  - Receipt image thumbnail
- "Save Item" primary CTA, "Enter Manually" fallback link
- Error state: "Couldn't read receipt — enter details manually"

**SwiftUI Components:**
- `UIViewControllerRepresentable` for camera
- `PhotosPicker` for library
- `Form` with `TextField`, `DatePicker`
- `ProgressView` for OCR spinner
- Sheet presentation from Home `+` button

---

## 3. Item Detail

**Purpose:** Full view of a single item with receipt image, countdown timers, and actions.

**Key UI Elements:**
- Receipt image (full-width, tappable to zoom)
- Item name + retailer (large title)
- Two countdown cards side-by-side:
  - Return window (days remaining or "Expired")
  - Warranty period (years/months/days or "No warranty")
- Action buttons:
  - "Mark Returned / Claimed" (primary)
  - "Edit Item" (secondary)
  - "Set Custom Reminder" (secondary)
  - "Delete Item" (destructive, in context menu)
- Notification status chip ("Reminders on / off")

**SwiftUI Components:**
- `ScrollView` + `VStack`
- `AsyncImage` or `Image` from local/iCloud data
- Custom countdown card view
- `Button` with `.buttonStyle`
- `.contextMenu` for destructive actions
- `.sheet` for edit flow

---

## 4. Archive

**Purpose:** Browse past items (returned, claimed, expired warranties). Searchable.

**Key UI Elements:**
- Search bar (`.searchable` modifier)
- Filter chips: All / Returned / Expired / Claimed
- Sorted list: most recently archived first
- Each row: item name, retailer, archive reason badge, archive date
- Tap → Item Detail (read-only mode, no action buttons)
- Empty state per filter: "No returned items yet"

**SwiftUI Components:**
- `NavigationStack`
- `.searchable(text:)`
- `List` with section grouping by month
- Custom filter chip row (`ScrollView(.horizontal)`)
- `TabView` (tab 2)

---

## 5. Settings

**Purpose:** Notification preferences, Pro tier management, iCloud sync status.

**Key UI Elements:**
- **Notifications section:**
  - Master toggle (enable/disable all reminders)
  - Reminder intervals: 7 days / 3 days / 1 day (multi-select toggles)
  - "Open System Settings" link if permission denied
- **Pro tier section:**
  - Current plan chip (Free / Pro)
  - "Upgrade to Pro — $2.99/mo" CTA (hidden if already Pro)
  - "Restore Purchases" button
- **iCloud Sync section:**
  - Sync status indicator (On / Off / Error)
  - "Enable iCloud Sync" toggle (Pro feature gate)
- **About section:**
  - App version, privacy policy link, rate the app

**SwiftUI Components:**
- `Form` with `Section` groups
- `Toggle`
- `Link` for external URLs
- `TabView` (tab 3)
- StoreKit 2 purchase sheet (modal)

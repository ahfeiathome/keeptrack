# KeepTrack — PRD Checklist

> Last updated: 2026-04-10 (added Lane 3 P1 from MRD v2, 2026-04-09)

## P0 — Must Ship (Lanes 1+2: Returns + Warranties)

| ID | Item | Category | Status | Owner | Target | GitHub |
|----|------|----------|--------|-------|--------|--------|
| KT-001 | Receipt Capture — camera + OCR extraction | Functional | Done | Code CLI | Done | CaptureSheet.swift + OCRService.swift — Vision framework, extracts store, date, items, total |
| KT-002 | Return Deadline Tracking — per-item countdown | Functional | Done | Code CLI | Done | returnDeadline field; StoreMatcher auto-computes deadline; HomeView sorted by deadline |
| KT-003 | Warranty Tracking — expiration dates | Functional | Partial | Code CLI | May 2026 | warrantyDeadline/warrantyMonths in Core Data model; HomeView sorts by it; no UI to set warranty date in CaptureSheet |
| KT-004 | Push Notifications — 7d/3d/1d reminders | Functional | Done | Code CLI | Done | ReminderScheduler.intervals=[7,3,1]; fires at 9am; cancels on return/delete |
| KT-005 | iCloud Sync — cross-device via CloudKit | Infrastructure | Done | Code CLI | Done | NSPersistentCloudKitContainer with automaticallyMergesChangesFromParent=true |
| KT-006 | Store Library — top 20 retailer return policies | Functional | Done | Code CLI | Done | stores.json has 30 retailers with accurate return days (Target 90d, Best Buy 15d, Apple 14d, etc.) |
| KT-007 | Archive Screen — expired/returned items | UI/UX | Done | Code CLI | Done | ArchiveView.swift — isReturned==YES OR returnDeadline<now, searchable |
| KT-008 | StoreKit 2 Pro Tier — $3.99/mo unlimited | Revenue | Done | Code CLI | Done | Full StoreKit 2: purchase, restore, transaction listener, refund detection. 10-item free limit. |

## P1 — Lane 3: Subscription Audit (NEW — absorbed from SubCheck, approved 2026-04-09)

> Source: S2_MRD.md v2. Do NOT build until Apple Developer account ($99) is active and TestFlight is running.

| ID | Item | Category | Status | Owner | Target | GitHub |
|----|------|----------|--------|-------|--------|--------|
| KT-013 | Manual Subscription Entry — logo + category auto-detect | Functional | Not Started | Code CLI | Q3 2026 | |
| KT-014 | Monthly Burn Rate Dashboard — total spend by category | UI/UX | Not Started | Code CLI | Q3 2026 | |
| KT-015 | Waste Score — flags subscriptions unused 30+ days | Functional | Not Started | Code CLI | Q3 2026 | |
| KT-016 | Cancel Guides — step-by-step for top 50 services | Functional | Not Started | Code CLI | Q3 2026 | |
| KT-017 | Trial Expiration Reminders — push before trial ends | Functional | Not Started | Code CLI | Q3 2026 | |
| KT-018 | Category Breakdown — streaming, productivity, fitness, news | UI/UX | Not Started | Code CLI | Q3 2026 | |

## P1 — Other (existing)

| ID | Item | Category | Status | Owner | Target | GitHub |
|----|------|----------|--------|-------|--------|--------|
| KT-009 | Bulk Export — CSV/PDF for records | Functional | Not Started | Code CLI | May 2026 | |
| KT-010 | TestFlight Beta — external testers | QA/Testing | Not Started | Code CLI | May 2026 | |

## P2 — Later

| ID | Item | Category | Status | Owner | Target | GitHub |
|----|------|----------|--------|-------|--------|--------|
| KT-011 | Email Receipt Parsing — auto-import | AI/ML | Not Started | Code CLI | Q3 2026 | |
| KT-012 | Shared Household — multi-user sync | Functional | Not Started | Code CLI | Q3 2026 | |

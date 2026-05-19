# SmartScanner PRD (Product Requirements Document)

## Executive Summary

SmartScanner is a receipt scanning and expense tracking application. The app enables users to capture or import receipt photos, extract structured data via OCR, and visualize spending patterns against a monthly budget.

**Target User:** Individual consumers who want to track discretionary and business expense receipts without manual data entry.

**Core Value Proposition:** "Scan a receipt. Track your spending. Know your budget." Eliminate tedious receipt entry while providing category-based spending insights and budget tracking.

---

## In-Scope Features (Currently Implemented)

### Receipt Capture & Import
- Capture receipt photos directly via device camera.
- Import receipt images from device gallery or photo library.
- Store imported images locally as base64-encoded gallery records.

### Receipt Data Extraction (OCR)
- Extract raw text from receipt images using ML Kit Text Recognition (Latin script only).
- Extract structured entities (store name, amount, date) using ML Kit Entity Extraction (English language only).
- Fallback rules:
  - Store name: First non-empty line of OCR text, or "Unknown Shop" if empty.
  - Amount: Largest monetary entity found via entity extraction, or 0.0 if none.
  - Date: First date entity found, or today's date if none.
  - Receipt ID: Millisecond timestamp (unique per device session).
  - Time field: Always empty (not extracted).
  - Items list: Always empty (item-level extraction not implemented).

### Receipt Storage & Persistence
- Store receipts locally in SharedPreferences (unencrypted).
- Persist monthly budget value locally.
- Publish receipts to Firestore for cross-device sync (read path not yet unified; see Known Issues).
- Each receipt record contains: id, storeName, date, time, total, category, timestamp, rawText (OCR output), galleryImageId (optional link), and `firestoreId` (optional) when synchronized to Firestore.

Sync model (current implementation): Local-first. Receipts are persisted locally in SharedPreferences and are published to Firestore asynchronously. After a successful Firestore write, the Firestore document id is captured as `firestoreId` and persisted into the local receipt record to enable reliable cross-referencing and reconciliation.

### Receipt Organization & Management
- Categorize receipts into 10 predefined categories: Food, Furniture, Stationery, Medicine, BabyAccessories, MobileAccessories, PetItems, BankPayment, Transport, Other.
- Default category: Other (no auto-categorization logic implemented).
- Allow manual category reassignment after capture.
- Delete individual receipts.
- Delete gallery images.

### Analytics & Dashboard
- Display current month's total spending vs. monthly budget.
- Show budget utilization percentage.
- Display visual warning (red) if spending exceeds budget.
- Show 7-day daily spending trend (bar chart).
- Show category breakdown (pie chart) with color-coded categories.
- Recompute aggregates on every app interaction (not cached).

### Budget Management
- Set/edit monthly budget value.
- Persist budget value locally.
- Compare current month's spending against budget.
- Default budget: 20,000 (local currency units, no currency conversion).

### UI Navigation & Interaction
- Tab-based interface: Dashboard (analytics), Vault (gallery images), Archive (receipt history).
- Floating action button for scan/import options.
- Loading spinner during receipt processing.
- Error notifications for processing failures.
- Deletion confirmation dialogs.

---

## Out-of-Scope Features (Intentionally Excluded)

### Data & Parsing
- **Item-level extraction:** Receipts capture total amount only; individual line-item parsing is not implemented.
- **Auto-categorization:** Receipts do not auto-assign categories. Users must manually select after capture.
- **Duplicate detection:** No check for duplicate receipts.
- **Amount validation:** No lower/upper bound enforcement on receipt totals.
- **Multilingual OCR:** Support for Sinhala, Tamil, or other scripts is not implemented (Latin script only).
- **Multilingual entity extraction:** English only; other language receipt parsing is not supported.
- **Currency conversion:** All amounts stored in local units with no currency conversion.

### Gemini AI Service
- A Gemini-based extraction service exists in the codebase but is **not wired into the runtime flow**.
- It is intentionally disabled and should not be considered a feature until explicitly integrated via an ADR.

### Data Sync & Cross-Device
- Firestore publishing is implemented but the read path is not yet unified.
- Cross-device sync is **not guaranteed** until the data-flow unification is complete (see PLAN.md, Phase 1).

### Testing & Quality Gates
- No automated tests match current app behavior (template test still exists).
- No CI/CD pipeline enforces test or lint gates.

### User Accounts & Authentication
- No user authentication.
- No multi-user or multi-device sync.
- Data is device-local only (except experimental Firestore writes).

### Advanced Analytics & Reporting
- No monthly/yearly trend analysis.
- No spending forecasting.
- No export (CSV, PDF, etc.).
- No data visualization beyond budget and category pie charts.

### Backend & Cloud Features
- No cloud-based data backup.
- No multi-device data sync (Firestore writes are incomplete).
- No serverless processing or webhooks.

### Mobile Permissions & Privacy
- iOS privacy descriptions (NSCameraUsageDescription, NSPhotoLibraryUsageDescription) are **not yet configured**.
- App will crash on iOS if camera/photo features are accessed without Info.plist entries.

---

## Known Limitations & Technical Debt

1. **Broken data flow:** Receipts are written to Firestore, but the UI reads from local storage only. Unified read/write path is required (PLAN.md, Phase 1).
2. **Monolithic architecture:** main.dart handles UI, state, and orchestration; refactoring required for maintainability (PLAN.md, Phase 2).
3. **OCR quality constraints:** Latin script and English entity extraction only. Local receipts in other languages will fail to parse.
4. **Gallery workflow incomplete:** Gallery images are saved, but the end-to-end link between images and receipts is unclear.
5. **Dashboard performance:** Aggregates recomputed on every rebuild; no caching or precomputation.
6. **Security gaps:** API key hardcoded in source; Firebase environment separation missing.
7. **Test coverage:** Current test file does not exercise app functionality.

---

## Success Criteria

The app is considered production-ready when:

1. ✓ Users can scan or import receipt images.
2. ✓ Receipt data is extracted and displayed accurately (within OCR constraints).
3. ✓ Receipts persist across app restarts.
4. ✓ Dashboard accurately reflects current month's spending vs. budget.
5. ✓ Firestore and local storage are aligned (single source of truth).
6. ✓ iOS privacy permissions are configured and tested.
7. ✓ Tests pass for critical flows (capture → parse → display, budget calculations).
8. ✓ Error handling is informative and does not crash the app.

---

## Future Roadmap (Out of Current Scope)

- Item-level receipt extraction (requires advanced OCR or Gemini integration).
- Auto-categorization (requires ML model training or Gemini prompt engineering).
- Multilingual support (requires language detection and dual OCR pipelines).
- User authentication and cross-device sync.
- Export and advanced reporting.
- Receipt image OCR in-app viewer and correction UI.

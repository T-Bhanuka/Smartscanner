# Data Dictionary — SmartScanner

This file describes the core entities, their field types, required/optional status, serialization keys, defaults, and persistence mapping as implemented in the codebase.

## Category (enum)
- Values: Food, Furniture, Stationery, Medicine, BabyAccessories, MobileAccessories, PetItems, BankPayment, Transport, Other
- Stored as: string (enum.name)

## Receipt
- Type: object
- Required fields:
  - `id` (String)
  - `storeName` (String)
  - `date` (String)
  - `time` (String)
  - `items` (List<ReceiptItem>)
  - `total` (double)
  - `category` (Category) stored as enum.name
  - `timestamp` (int)
- Optional fields:
  - `rawText` (String?)
  - `galleryImageId` (String?)
- Serialization keys (toJson/fromJson): `id`, `storeName`, `date`, `time`, `items`, `total`, `category`, `timestamp`, `rawText`, `galleryImageId`

## ReceiptItem
- Type: object
- Fields:
  - `name` (String) — required
  - `price` (double) — required
  - `category` (Category) stored as enum.name — required
- Serialization keys: `name`, `price`, `category`

## GalleryImage
- Type: object
- Required fields:
  - `id` (String)
  - `base64` (String) — image bytes base64-encoded
  - `timestamp` (int)
- Optional fields:
  - `isProcessed` (bool) default: false
  - `linkedReceiptId` (String?)
- Serialization keys: `id`, `base64`, `timestamp`, `isProcessed`, `linkedReceiptId`

## AppState (state fields)
- `receipts` : List<Receipt> — in-memory list of receipts
- `galleryImages` : List<GalleryImage> — in-memory gallery
- `isAnalyzing` : bool — processing flag
- `analysisError` : String? — last analysis error message
- `monthlyBudget` : double — persisted in receipts storage bundle

Mutation points (where these are updated):
- `AppState.loadData()` — loads `receipts`, `galleryImages`, and `monthlyBudget` from `ReceiptRepository` and notifies listeners.
- `AppState.processReceipt(imagePath)` — toggles `isAnalyzing`, calls processing service, saves receipt via `ReceiptRepository.addReceipt`, inserts into `receipts` and notifies.
- `AppState.pickImageFromGallery()` — creates `GalleryImage`, saves via `ReceiptRepository.saveGalleryImage`, inserts into `galleryImages`, then calls `processReceipt`.
- `AppState.deleteGalleryItem(id)` — removes from `galleryImages`, calls `ReceiptRepository.deleteGalleryImage`.
- `AppState.deleteReceipt(id)` and `updateBudget(value)` — persist receipts and monthlyBudget via `ReceiptRepository.saveReceipts`.

## Persistence mapping
- Local storage (SharedPreferences):
  - Receipts & budget stored under key: `receipt_app_pro_v5_data`.
    - JSON shape: { "receipts": [ ...Receipt objects... ], "monthlyBudget": <number> }
  - Gallery images stored under key: `receipt_app_gallery_v5`.
    - JSON shape: array of `GalleryImage` JSON objects

- Firestore: collection `receipts` (published on add)
  - Fields written when publishing:
    - `storeName` (String)
    - `totalAmount` (number)  <-- note: code uses `totalAmount` here
    - `date` (String)
    - `time` (String)
    - `category` (String)
    - `rawText` (String)
    - `items` (List<Map<String, dynamic>>) — each item uses `name`, `price`, `category`
    - `timestamp` (int)

## Notes and constraints
- The in-code `Receipt.toJson()` uses the key `total` while Firestore publish uses `totalAmount` — this is an intentional implementation detail and a potential mismatch for downstream consumers.
- Processed receipts produced by `ReceiptProcessingService` currently set `items` to an empty list and `category` to `Category.Other` by default.

## Checklist for agents
- Verify enum values are exhaustive vs UI expectations.
- Confirm whether Firestore consumers expect `total` or `totalAmount` and unify.
- Add mapping matrix from local storage shape → Firestore shape.
- Add unit tests for (de)serialization of `Receipt` and `GalleryImage`.
# Data Dictionary

This document defines the exact data structures, field types, constraints, and persistence contracts for SmartScanner. Future agents must reference this when reading, writing, or transforming receipt data.

---

## Core Entities

### Receipt

Represents a scanned or imported expense receipt.

| Field | Type | Required | Constraints | Serialization | Source |
|-------|------|----------|-------------|---------------|--------|
| `id` | `String` | Yes | Unique per device session; format: millisecond timestamp (e.g., "1715858400000") | JSON key 'id' | Generated at receipt creation time in `receipt_processing_service.dart` |
| `storeName` | `String` | Yes | Non-empty; defaults to "Unknown Shop" if OCR produces empty first line | JSON key 'storeName' | Extracted from OCR text (first non-empty line) |
| `date` | `String` | Yes | ISO8601 format (e.g., "2024-05-15") or any string format returned by ML Kit entity extraction; fallback to current date if no date entity found | JSON key 'date' | Extracted from ML Kit entity extraction (first dateTime entity) or DateTime.now().toIso8601String() |
| `time` | `String` | Yes | Empty string; not currently extracted or validated | JSON key 'time' | Always '' (empty) |
| `items` | `List<ReceiptItem>` | Yes | Always empty list; item-level extraction not implemented | JSON key 'items' mapped to array of ReceiptItem.toJson() | Hardcoded as [] |
| `total` | `double` | Yes | Non-negative; no upper bound enforced; default 0.0 if no money entity found; no currency symbol | JSON key 'total' (float) | Extracted from ML Kit entity extraction (largest money entity) |
| `category` | `Category` (enum) | Yes | One of: Food, Furniture, Stationery, Medicine, BabyAccessories, MobileAccessories, PetItems, BankPayment, Transport, Other; default is Other | JSON key 'category' (string name of enum, e.g., "Food") | User-selected after extraction; defaults to `Category.Other` |
| `timestamp` | `int` | Yes | Milliseconds since epoch; set at receipt creation | JSON key 'timestamp' | DateTime.now().millisecondsSinceEpoch |
| `rawText` | `String?` | No | Full OCR output from ML Kit Text Recognition; nullable | JSON key 'rawText' (nullable string) | Entire recognized text output from TextRecognizer.processImage() |
| `galleryImageId` | `String?` | No | Links to `GalleryImage.id` if receipt came from imported gallery image; nullable | JSON key 'galleryImageId' (nullable string) | Set only if receipt was created from a gallery image; otherwise null |

**Serialization Contract:**

```dart
Map<String, dynamic> toJson() => {
  'id': id,
  'storeName': storeName,
  'date': date,
  'time': time,
  'items': items.map((e) => e.toJson()).toList(),
  'total': total,
  'category': category.name,
  'timestamp': timestamp,
  'rawText': rawText,
  'galleryImageId': galleryImageId,
};

factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
  id: json['id'],
  storeName: json['storeName'],
  date: json['date'],
  time: json['time'],
  items: (json['items'] as List).map((e) => ReceiptItem.fromJson(e)).toList(),
  total: (json['total'] as num).toDouble(),
  category: Category.values.firstWhere((e) => e.name == json['category']),
  timestamp: json['timestamp'],
  rawText: json['rawText'] as String?,
  galleryImageId: json['galleryImageId'],
);
```

**Persistence:**
- **Local (SharedPreferences):** Stored under key `'receipt_app_pro_v5_data'` as JSON array within object `{ 'receipts': [...], 'monthlyBudget': 20000 }`.
- **Remote (Firestore):** Published to collection `'receipts'` with fields: storeName, totalAmount, date, time, category (enum name as string), rawText, items (array), timestamp.
- **Location in code:** [lib/types.dart](lib/types.dart) (definition), [lib/services/receipt_processing_service.dart](lib/services/receipt_processing_service.dart) (creation), [lib/services/storage_service.dart](lib/services/storage_service.dart) (local persistence), [lib/services/receipt_repository.dart](lib/services/receipt_repository.dart) (Firestore publishing).

---

### ReceiptItem

Represents a line item on a receipt (e.g., "Milk - 5.50").

**Status:** Defined but **never populated**. All Receipt.items arrays are empty. This structure exists for future item-level extraction.

| Field | Type | Required | Constraints | Serialization | Source |
|-------|------|----------|-------------|---------------|--------|
| `name` | `String` | Yes | Product name; non-empty | JSON key 'name' | (Future) Extracted from receipt text |
| `price` | `double` | Yes | Non-negative; no upper bound | JSON key 'price' (float) | (Future) Extracted from receipt text |
| `category` | `Category` (enum) | Yes | One of the 10 Category enum values | JSON key 'category' (string name) | (Future) Auto-categorized or user-assigned |

**Serialization Contract:**

```dart
Map<String, dynamic> toJson() => {
  'name': name,
  'price': price,
  'category': category.name,
};

factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
  name: json['name'],
  price: json['price'],
  category: Category.values.firstWhere((e) => e.name == json['category']),
);
```

**Persistence:**
- **Local:** Nested within Receipt JSON under 'items' key (array of ReceiptItem.toJson()).
- **Remote:** Nested within Firestore receipt document under 'items' field (array).
- **Location in code:** [lib/types.dart](lib/types.dart).

---

### GalleryImage

Represents a receipt image stored locally (user's device) without OCR extraction.

| Field | Type | Required | Constraints | Serialization | Source |
|-------|------|----------|-------------|---------------|--------|
| `id` | `String` | Yes | Unique identifier; format: millisecond timestamp (e.g., "1715858400123") | JSON key 'id' | Generated at import time: DateTime.now().millisecondsSinceEpoch.toString() |
| `base64` | `String` | Yes | Full base64-encoded image data; decoded from picked image file bytes | JSON key 'base64' | base64Encode(pickedFile.readAsBytes()) |
| `timestamp` | `int` | Yes | Milliseconds since epoch; creation time | JSON key 'timestamp' | DateTime.now().millisecondsSinceEpoch |
| `isProcessed` | `bool` | No | Flag indicating if image has been OCR-processed; default false | JSON key 'isProcessed' (defaults to false if missing) | Set to false on creation; never updated in current implementation |
| `linkedReceiptId` | `String?` | No | Links to Receipt.id if this image was the source of a scanned receipt; nullable | JSON key 'linkedReceiptId' (nullable) | (Future) Set after OCR extraction if image is used for receipt creation |

**Serialization Contract:**

```dart
Map<String, dynamic> toJson() => {
  'id': id,
  'base64': base64,
  'timestamp': timestamp,
  'isProcessed': isProcessed,
  'linkedReceiptId': linkedReceiptId,
};

factory GalleryImage.fromJson(Map<String, dynamic> json) => GalleryImage(
  id: json['id'],
  base64: json['base64'],
  timestamp: json['timestamp'],
  isProcessed: json['isProcessed'] ?? false,
  linkedReceiptId: json['linkedReceiptId'],
);
```

**Persistence:**
- **Local (SharedPreferences):** Stored under key `'receipt_app_gallery_v5'` as JSON array.
- **Remote:** Not synced to Firestore (local only).
- **Location in code:** [lib/types.dart](lib/types.dart) (definition), [lib/services/storage_service.dart](lib/services/storage_service.dart) (persistence), [lib/view_models/app_state.dart](lib/view_models/app_state.dart) (lifecycle).

---

### Category (Enum)

Represents a spending category for organizing receipts.

```dart
enum Category {
  Food,
  Furniture,
  Stationery,
  Medicine,
  BabyAccessories,
  MobileAccessories,
  PetItems,
  BankPayment,
  Transport,
  Other,
}
```

**Constraints:**
- Fixed set of 10 values; no custom categories.
- Default value: `Category.Other`.
- Serialized as string name (e.g., "Food" for Category.Food).
- Deserialized via `Category.values.firstWhere((e) => e.name == json['category'])`.

**Color Mapping (in dashboard.dart):**
- Food → CupertinoColors.systemRed
- Furniture → Colors.orange
- Stationery → Colors.yellow
- Medicine → Colors.green
- BabyAccessories → Colors.cyan
- MobileAccessories → Colors.blue
- PetItems → Colors.deepPurple
- BankPayment → Colors.grey
- Transport → Colors.teal
- Other → Colors.blueGrey

**Location in code:** [lib/types.dart](lib/types.dart).

---

## Persistence Layer Contracts

### Local Storage (SharedPreferences)

**Provider:** SharedPreferences (`shared_preferences` package).

**Keys:**

| Key | Type | Structure | Owner | Default |
|-----|------|-----------|-------|---------|
| `'receipt_app_pro_v5_data'` | JSON String | `{ "receipts": [...], "monthlyBudget": <double> }` | StorageService | `'{"receipts":[],"monthlyBudget":20000}'` |
| `'receipt_app_gallery_v5'` | JSON String | Array of GalleryImage.toJson() | StorageService | `'[]'` |

**Read Path:**
- `StorageService.getAllReceipts()` → deserialize 'receipt_app_pro_v5_data' → map to List<Receipt>.
- `StorageService.getMonthlyBudget()` → extract 'monthlyBudget' from 'receipt_app_pro_v5_data'.
- `StorageService.getAllGalleryImages()` → deserialize 'receipt_app_gallery_v5' → map to List<GalleryImage>.

**Write Path:**
- `StorageService.saveReceipts(receipts, budget)` → serialize List<Receipt> and budget → write as single JSON object to 'receipt_app_pro_v5_data'.
- `StorageService.saveGalleryImage(image)` → upsert single GalleryImage → rewrite entire 'receipt_app_gallery_v5' array.
- `StorageService.deleteGalleryImage(id)` → filter out by id → rewrite entire 'receipt_app_gallery_v5' array.

**Constraints:**
- Unencrypted.
- No validation on read (assumes data integrity from previous write).
- Atomic per key (no partial updates within a key).

**Location in code:** [lib/services/storage_service.dart](lib/services/storage_service.dart).

---

### Remote Storage (Firestore)

**Provider:** Cloud Firestore (`cloud_firestore` package).

**Firebase Project:** receptscanner-2878a (see `lib/firebase_options.dart`).

**Collections:**

| Collection | Document ID | Fields | Write Source | Read Status |
|-----------|-------------|--------|--------------|-------------|
| `'receipts'` | Auto-generated or `Receipt.id` | storeName, totalAmount, date, time, category (string), rawText, items (array), timestamp | `ReceiptRepository._publishReceiptToFirestore()` | Not wired; see PLAN.md Phase 1 |

**Document Fields (Sample):**

```json
{
  "storeName": "Grocery Store A",
  "totalAmount": 45.99,
  "date": "2024-05-15",
  "time": "",
  "category": "Food",
  "rawText": "[Full OCR output...]",
  "items": [],
  "timestamp": 1715858400000
}
```

**Constraints:**
- No server-side validation.
- No duplicate-receipt detection.
- Receipts are append-only (no conflict resolution for updates).
- Cross-device sync is **not guaranteed** until read path is unified (see PLAN.md, Phase 1).

**Location in code:** [lib/services/receipt_repository.dart](lib/services/receipt_repository.dart).

---

## State Management (AppState)

**Provider:** Provider (`provider` package).

**Owned State:**

| State Field | Type | Initial Value | Read by | Mutated by |
|-------------|------|---------------|---------|-----------|
| `receipts` | `List<Receipt>` | `[]` | Dashboard, Archive tabs | `processReceipt()`, `deleteReceipt()`, `loadData()` |
| `galleryImages` | `List<GalleryImage>` | `[]` | Vault tab (GridView) | `pickImageFromGallery()`, `deleteGalleryItem()`, `loadData()` |
| `isAnalyzing` | `bool` | `false` | UI (loading spinner overlay) | `processReceipt()` (entry and finally) |
| `analysisError` | `String?` | `null` | UI (error snackbar) | `processReceipt()` (catch block), `clearError()` |
| `monthlyBudget` | `double` | `20000` | Dashboard (budget card) | `updateBudget()`, `loadData()` |

**Mutation Points:**

```
loadData()
  → StorageService.getAllReceipts() → receipts = [...]
  → StorageService.getMonthlyBudget() → monthlyBudget = ...
  → StorageService.getAllGalleryImages() → galleryImages = [...]

processReceipt(imagePath)
  → isAnalyzing = true
  → analysisError = null
  → ReceiptProcessingService.processReceiptImage(imagePath) → Receipt
  → ReceiptRepository.addReceipt(receipt, ...) → receipts.insert(0, receipt)
  → [catch] analysisError = error message
  → [finally] isAnalyzing = false
  → notifyListeners()

pickImageFromGallery()
  → ImagePicker.pickImage() → file
  → base64Encode(file.readAsBytes()) → GalleryImage
  → ReceiptRepository.saveGalleryImage() → galleryImages.insert(0, ...)
  → processReceipt(filePath) → same as processReceipt()

deleteReceipt(id)
  → receipts.removeWhere((r) => r.id == id)
  → ReceiptRepository.deleteReceipt() [not implemented; assumed]
  → notifyListeners()

deleteGalleryItem(id)
  → galleryImages.removeWhere((g) => g.id == id)
  → ReceiptRepository.deleteGalleryImage() → StorageService.deleteGalleryImage()
  → notifyListeners()

updateBudget(value)
  → monthlyBudget = value
  → ReceiptRepository.updateBudget() [not confirmed; assumed delegates to StorageService]
  → notifyListeners()

clearError()
  → analysisError = null
  → notifyListeners()
```

**Location in code:** [lib/view_models/app_state.dart](lib/view_models/app_state.dart).

---

## Data Flow Summary

### User Initiates Receipt Capture

```
HomePage (UI)
  → Camera capture or gallery pick
  → _processReceipt(imagePath) [HomePage method]
  → AppState.processReceipt(imagePath)
    → isAnalyzing = true
    → ReceiptProcessingService.processReceiptImage(imagePath)
      → ML Kit Text Recognition → rawText
      → ML Kit Entity Extraction → annotations
      → Extract shopName, total, date
      → Build Receipt object
    → ReceiptRepository.addReceipt(receipt)
      → StorageService.saveReceipts([receipt, ...existing])
      → ReceiptRepository._publishReceiptToFirestore(receipt) [async, not awaited]
    → AppState.receipts.insert(0, receipt)
    → Dashboard, Archive tabs rebuild from receipts list
```

### User Imports Gallery Image

```
HomePage (UI)
  → _pickFromGallery()
  → AppState.pickImageFromGallery()
    → ImagePicker.pickImage(source: ImageSource.gallery)
    → Read file bytes → base64Encode() → GalleryImage
    → ReceiptRepository.saveGalleryImage(galleryImage)
      → StorageService.saveGalleryImage(galleryImage)
    → AppState.galleryImages.insert(0, galleryImage)
    → AppState.processReceipt(filePath) [immediately after]
      → (same as capture flow above)
    → Vault tab rebuilds with new gallery image
```

### Dashboard Computation (Rebuild Path)

```
Dashboard widget (lib/components/dashboard.dart)
  → AppState.watch<AppState>() changes
  → Dashboard.build() called
    → Aggregate receipts by date (last 7 days)
    → Aggregate receipts by category
    → Sum total by month
    → Compare to monthlyBudget
    → Rebuild charts
  [No caching; recomputes every rebuild]
```

---

## Important Constraints & Assumptions

1. **No item-level data:** ReceiptItem.items is always empty; total amount is the only numerical data.
2. **No duplicate detection:** The system does not prevent duplicate receipt creation.
3. **No amount validation:** Any non-negative double is accepted; no bounds enforced.
4. **No date normalization:** Date strings are stored as returned by ML Kit; no validation or parsing.
5. **No user authentication:** All data is local to the device (except Firestore writes, which are unvalidated).
6. **No encryption:** SharedPreferences data is unencrypted.
7. **Firestore writes are async and not awaited:** Published receipts may not appear in Firestore if the app crashes or network fails.
8. **Gallery-receipt link is unimplemented:** GalleryImage.linkedReceiptId is not populated by the current code.
9. **No cache invalidation strategy:** Dashboard recomputes on every rebuild.

---

## Future Extensions (Not Yet Implemented)

When adding features, agents should extend the data dictionary:

- **User authentication:** Add userId field to Receipt, GalleryImage; partition Firestore collections by user.
- **Item-level extraction:** Populate ReceiptItem.items via Gemini or advanced OCR.
- **Auto-categorization:** Add confidence score field to Receipt.category; implement categorization logic.
- **Multilingual support:** Add languageDetected and ocrScript fields to Receipt; extend enum for language variants.
- **Export:** Define CSV/PDF serialization contracts for Receipt and aggregated reports.
- **Duplicate detection:** Add hash or fuzzy-match logic for Receipt deduplication; add isCandidate bool field.

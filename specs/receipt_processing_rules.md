# Receipt Processing Rules & Logic Ledger

## Overview
This document captures the complete business logic for receipt processing in SmartScanner. It describes the exact data flow, state mutations, validations, and persistence operations involved when a user scans or selects a receipt image.

---

## Data Flow: From Image Selection to UI Update

### Trigger Point: User selects or captures receipt image

**Actors:**
- `HomePage._pickFromGallery()` (UI, main.dart)
- `HomePage._processReceipt()` (UI, main.dart)
- `AppState` (ViewModel, app_state.dart)
- `ReceiptProcessingService` (Service, receipt_processing_service.dart)
- `ReceiptRepository` (Service, receipt_repository.dart)
- `StorageService` (Infrastructure, storage_service.dart)

---

## Step-by-Step Data Flow

### Phase 1: User Action & Gallery Management

**Step 1.1: UI initiates gallery pick**
- User taps FAB or "Gallery" option in main.dart
- `HomePage._pickFromGallery()` is called
- **Effect:** Modal closes, `isFabOpen = false` (local UI state)

**Step 1.2: AppState handles gallery selection**
- `_pickFromGallery()` calls `context.read<AppState>().pickImageFromGallery()`
- **Function:** AppState.pickImageFromGallery()
  - Uses `ImagePicker().pickImage(source: ImageSource.gallery)` to select file
  - If no file selected, method returns early

**Step 1.3: Gallery image creation and persistence**
- If file selected:
  - Read file bytes: `pickedFile.readAsBytes()`
  - Encode to base64: `base64Encode(bytes)`
  - Create `GalleryImage` domain model:
    - `id`: timestamp in milliseconds
    - `base64`: image bytes as base64 string
    - `timestamp`: creation time in milliseconds
    - `isProcessed`: false (initial state)
    - `linkedReceiptId`: null (set later after processing)

**Step 1.4: Update UI state with new gallery image**
- Insert image at front of `galleryImages` list
- Call `notifyListeners()` → UI rebuilds `_buildGalleryTab()`
- **State mutation:** `galleryImages.insert(0, galleryImage)`

**Step 1.5: Persist gallery image locally**
- Call `ReceiptRepository.saveGalleryImage(galleryImage)`
- ReceiptRepository delegates to `StorageService.saveGalleryImage()`
- **Persistence logic:**
  - Fetch current gallery list from SharedPreferences
  - Check if image already exists by `id`
  - If exists: update in place
  - If new: insert at front of list
  - Re-encode entire list to JSON and save to `_galleryKey`

**Step 1.6: Trigger receipt processing**
- After gallery save completes, call `await processReceipt(pickedFile.path)`
- Pass file system path (not base64) to processing service

---

### Phase 2: Receipt Image Processing (ML-based OCR & Entity Extraction)

**Step 2.1: Initialize processing state**
- **Function:** AppState.processReceipt()
- **State mutations:**
  - `isAnalyzing = true` (show spinner in UI)
  - `analysisError = null` (clear previous errors)
  - `notifyListeners()`

**Step 2.2: Call ML Kit Text Recognition**
- **Function:** ReceiptProcessingService.processReceiptImage()
- **Logic:**
  - Create `InputImage` from file path
  - Instantiate `TextRecognizer` with Latin script
  - Call `textRecognizer.processImage(inputImage)`
  - Extract recognized text: `recognizedText.text` (full raw OCR output)
  - Close recognizer resource

**Step 2.3: Call ML Kit Entity Extraction**
- Instantiate `EntityExtractor` with English language
- Call `entityExtractor.annotateText(fullText)`
- Returns list of annotations with entity types and text spans
- Close extractor resource

**Step 2.4: Extract shop name (heuristic)**
- **Function:** `_extractShopName(fullText)`
- **Logic:**
  - Split raw text by newlines
  - Filter empty lines
  - Return first non-empty line trimmed, or "Unknown Shop" if empty

**Step 2.5: Extract monetary amount (heuristic)**
- **Logic:**
  - Iterate through all annotations from entity extraction
  - For each annotation with `EntityType.money`:
    - Strip non-numeric characters from annotation text: `replaceAll(RegExp(r'[^0-9.]'), '')`
    - Parse as double: `double.tryParse()`
    - Keep track of maximum value found (largest amount is total)
  - Default: `0.0` if no money entity found

**Step 2.6: Extract date (from ML entity extraction)**
- **Logic:**
  - Iterate through annotations
  - For each annotation with `EntityType.dateTime`:
    - Use annotation text directly as date
    - First match wins
  - **Fallback:** If no date entity found, use current date/time: `DateTime.now().toIso8601String()`

**Step 2.7: Build Receipt domain model**
- **Properties set:**
  - `id`: timestamp in milliseconds (unique identifier)
  - `storeName`: extracted shop name or "Unknown Shop"
  - `date`: extracted date or current date
  - `time`: empty string (not extracted from receipt)
  - `items`: empty list (item-level extraction not implemented)
  - `total`: extracted monetary amount
  - `category`: `Category.Other` (default, not auto-categorized)
  - `timestamp`: current time in milliseconds
  - `rawText`: full OCR output (for debugging/future processing)
  - `galleryImageId`: null (optional, for linking gallery images)

---

### Phase 3: Receipt Persistence (Local + Remote)

**Step 3.1: Add receipt to state and save locally**
- **Function:** AppState.processReceipt() (catch block)
- Call `ReceiptRepository.addReceipt(receipt, receipts, monthlyBudget)`
- **ReceiptRepository logic:**
  - Create new receipts list: `[receipt, ...currentReceipts]`
  - Call `StorageService.saveReceipts(updatedReceipts, monthlyBudget)`

**Step 3.2: Save receipts to SharedPreferences**
- **Function:** StorageService.saveReceipts()
- **Persistence logic:**
  - Get SharedPreferences instance
  - Serialize all receipts to JSON:
    - Each receipt mapped via `Receipt.toJson()`
    - Receipt includes: id, storeName, date, time, items[], total, category, timestamp, rawText, galleryImageId
  - Create JSON structure: `{ 'receipts': [...], 'monthlyBudget': value }`
  - Store under key `_receiptsKey` = `'receipt_app_pro_v5_data'`

**Step 3.3: Publish receipt to Firestore (remote)**
- **Function:** ReceiptRepository._publishReceiptToFirestore()
- **Firestore logic:**
  - Create document in collection `'receipts'`
  - **Fields stored:**
    - `storeName`: receipt.storeName
    - `totalAmount`: receipt.total
    - `date`: receipt.date
    - `time`: receipt.time
    - `category`: receipt.category.name (enum as string)
    - `rawText`: receipt.rawText (nullable, defaults to empty string)
    - `items`: receipt.items[] mapped to JSON
    - `timestamp`: receipt.timestamp (milliseconds since epoch)
  - **No validation on Firestore side** (client generates all fields)

**Step 3.4: Update UI state with new receipt**
- Insert receipt at front of `receipts` list: `receipts.insert(0, receipt)`
- Call `notifyListeners()`
- **Effect:** Dashboard and History tabs rebuild with new receipt

---

## State Mutations Summary

### AppState mutations during receipt processing:

| Operation | State Field | Change | Trigger |
|-----------|---|---|---|
| Start processing | `isAnalyzing` | `false` → `true` | `processReceipt()` entry |
| Clear previous error | `analysisError` | `<any>` → `null` | `processReceipt()` entry |
| Add processed receipt | `receipts` | insert at index 0 | After `addReceipt()` succeeds |
| Set error | `analysisError` | `null` → error message | Catch exception in `processReceipt()` |
| End processing | `isAnalyzing` | `true` → `false` | Finally block in `processReceipt()` |

All mutations trigger `notifyListeners()` to rebuild UI.

---

## Validations & Constraints

### Input Validations

| Input | Validation | Action on Failure |
|-------|---|---|
| Image file | Must exist and be readable | Exception propagates; caught in `processReceipt()` catch block |
| OCR output | No validation | Return empty string if ML Kit fails |
| Entity extraction | No validation | Return empty annotations if ML Kit fails |
| Monetary amount | Must parse as double | Default to `0.0` |
| Date | Must be valid string | Use current date as fallback |
| Shop name | No validation | Default to "Unknown Shop" |

### Business Rules

1. **Receipt uniqueness:** No check. Duplicate receipt detection not implemented.
2. **Amount validation:** No lower/upper bounds enforced.
3. **Date validation:** No format validation; accepts any string from ML Kit.
4. **Category assignment:** Always defaults to `Category.Other`; no auto-categorization.
5. **Gallery linking:** Receipts do not automatically link to gallery images.

---

## Database Structure

### Local Persistence (SharedPreferences)

**Key:** `'receipt_app_pro_v5_data'`

```json
{
  "receipts": [
    {
      "id": "1715644800000",
      "storeName": "ABC Supermarket",
      "date": "2024-05-14T...",
      "time": "",
      "items": [],
      "total": 1250.50,
      "category": "Other",
      "timestamp": 1715644800000,
      "rawText": "<full OCR output>",
      "galleryImageId": null
    }
  ],
  "monthlyBudget": 20000
}
```

**Key:** `'receipt_app_gallery_v5'`

```json
[
  {
    "id": "1715644800000",
    "base64": "<image bytes as base64>",
    "timestamp": 1715644800000,
    "isProcessed": false,
    "linkedReceiptId": null
  }
]
```

### Remote Persistence (Firestore)

**Collection:** `'receipts'`  
**Document ID:** Auto-generated

| Field | Type | Source |
|-------|------|--------|
| `storeName` | string | Extracted from first line of OCR |
| `totalAmount` | number | Largest monetary entity found |
| `date` | string | First date entity or current date |
| `time` | string | Empty (not extracted) |
| `category` | string | Always "Other" |
| `rawText` | string | Full OCR output |
| `items` | array | Empty (not extracted) |
| `timestamp` | number | Milliseconds since epoch |

---

## Error Handling

| Scenario           |              Source            |               Handling                    |
|--------------------|--------------------------------|------------------------------------------|
| Image file invalid | `ImagePicker.pickImage()`      | Caught in `processReceipt()` catch block |
| ML Kit unavailable | TextRecognizer/EntityExtractor | Caught in `processReceipt()` catch block |
| Firestore write fails | `FirebaseFirestore.instance`| Caught in `processReceipt()`; local save already completed |
| SharedPreferences fails | `SharedPreferences.getInstance()` | Caught in `processReceipt()` catch block |

**Error Display:** UI shows `analysisError` in error container; user can dismiss via `clearError()` button.

---

## Implementation Summary

The receipt processing is a three-phase pipeline:
1. **Gallery selection** → Create `GalleryImage` → Save locally
2. **ML processing** → OCR + entity extraction → Extract shop, amount, date
3. **Persistence** → Local save to SharedPreferences (durable) → Remote sync to Firestore (best-effort)

All operations notify listeners, triggering UI rebuilds. Errors caught and displayed in UI error container.

---
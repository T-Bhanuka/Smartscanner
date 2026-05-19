# Actual Implementation Logic — authoritative ledger

This document extracts the implemented logic from `lib/services` and `lib/view_models` and records exact method signatures, pseudocode (copied behavior), storage keys, Firestore mapping, and error paths.

## Key methods and behavior

### ReceiptProcessingService.processReceiptImage(String imagePath)
- Inputs: `imagePath` (String)
- Returns: `Future<Receipt>`
- Behavior (pseudocode, faithful to source):
  1. Create `InputImage` from `imagePath`.
 2. Create `TextRecognizer(script: latin)` and call `processImage(inputImage)` -> `recognizedText`.
 3. Store `fullText = recognizedText.text` and close recognizer.
 4. Create `EntityExtractor(language: english)` and call `annotateText(fullText)` -> `annotations`.
 5. Initialize `shopName = _extractShopName(fullText)`; `date = DateTime.now().toIso8601String()`; `totalAmount = 0.0`.
 6. Iterate annotations → for each entity: if `EntityType.money`, strip non-digits from `annotation.text` and parse as double; keep the maximum value into `totalAmount`. If `EntityType.dateTime`, set `date = annotation.text`.
 7. Close entityExtractor.
 8. Return new `Receipt` with:
     - `id`: millisecondsSinceEpoch string
     - `storeName`: shopName
     - `date`: date
     - `time`: ''
     - `items`: [] (empty list)
     - `total`: totalAmount
     - `category`: `Category.Other`
     - `timestamp`: now millis
     - `rawText`: fullText

### ReceiptProcessingService._extractShopName(String fullText)
- Simple heuristic: split `fullText` into non-empty lines and return the first line or `Unknown Shop`.

### StorageService (local persistence)
- Keys:
  - `_receiptsKey = 'receipt_app_pro_v5_data'`
  - `_galleryKey = 'receipt_app_gallery_v5'`
- getAllReceipts():
  - Read prefs.getString(_receiptsKey)
  - If null → return []
  - Else parse JSON and return parsed['receipts'].map(Receipt.fromJson)
- saveReceipts(receipts, monthlyBudget):
  - prefs.setString(_receiptsKey, jsonEncode({ 'receipts': receipts.map(toJson), 'monthlyBudget': monthlyBudget }))
- getMonthlyBudget():
  - Read prefs.getString(_receiptsKey)
  - If null → return 20000
  - Else return parsed['monthlyBudget'] ?? 20000
- Gallery methods:
  - getAllGalleryImages(): read _galleryKey (json array) -> map to GalleryImage.fromJson
  - saveGalleryImage(image): load all, replace or insert at index 0, write back json array
  - deleteGalleryImage(id): load all, remove where id==id, write back

### ReceiptRepository
- loadReceipts(), loadMonthlyBudget(), loadGalleryImages(), saveReceipts(...), saveGalleryImage(...), deleteGalleryImage(...) — thin wrappers over StorageService.
- addReceipt(Receipt receipt, List<Receipt> currentReceipts, double monthlyBudget):
  - Compose updatedReceipts = [receipt, ...currentReceipts]
  - await saveReceipts(updatedReceipts, monthlyBudget)
  - await _publishReceiptToFirestore(receipt)

- _publishReceiptToFirestore(Receipt receipt):
  - Calls `FirebaseFirestore.instance.collection('receipts').add({ ... })` with the following fields:
    - `storeName`: receipt.storeName
    - `totalAmount`: receipt.total
    - `date`: receipt.date
    - `time`: receipt.time
    - `category`: receipt.category.name
    - `rawText`: receipt.rawText ?? ''
    - `items`: receipt.items.map((item) => item.toJson()).toList()
    - `timestamp`: receipt.timestamp

  - Note: Firestore document is created via `.add()` (server generates doc id). The in-memory `Receipt.id` is not synced back to Firestore documents by this method.

### AppState (view_models/app_state.dart)
- Fields: `receipts`, `galleryImages`, `isAnalyzing`, `analysisError`, `monthlyBudget`
- loadData():
  - receipts = await ReceiptRepository.loadReceipts()
  - galleryImages = await ReceiptRepository.loadGalleryImages()
  - monthlyBudget = await ReceiptRepository.loadMonthlyBudget()
  - galleryImages.sort by timestamp desc
  - notifyListeners()
- processReceipt(imagePath):
  - isAnalyzing = true; analysisError = null; notify
  - try: receipt = await ReceiptProcessingService.processReceiptImage(imagePath)
    - await ReceiptRepository.addReceipt(receipt, receipts, monthlyBudget)
    - receipts.insert(0, receipt); notify
  - catch: analysisError = 'Error scanning: $e'; notify
  - finally: isAnalyzing = false; notify
- pickImageFromGallery():
  - Use ImagePicker().pickImage(source: gallery)
  - if picked: read bytes => base64 => create `GalleryImage` with id=nowMillisString, isProcessed=false
  - insert into galleryImages at 0, await ReceiptRepository.saveGalleryImage(galleryImage), notify, then call processReceipt(pickedFile.path)
- deleteGalleryItem(id): remove from galleryImages, call ReceiptRepository.deleteGalleryImage(id), notify
- deleteReceipt(id): remove from receipts, call ReceiptRepository.saveReceipts(receipts, monthlyBudget), notify
- updateBudget(value): set monthlyBudget, saveReceipts(...), notify
- clearError(): analysisError = null; notify

## Error handling paths
- Processing errors in `processReceipt` are caught and set `analysisError` to the error string. `isAnalyzing` is reset in `finally`.
- StorageService relies on SharedPreferences; it returns defaults (empty lists or 20000 for budget) when data is missing.

## Exact keys and shapes (reference)
- Local receipts storage (`receipt_app_pro_v5_data`):
  - Root object keys: `receipts` (array of Receipt JSON), `monthlyBudget` (number)
- Local gallery storage (`receipt_app_gallery_v5`): JSON array of GalleryImage objects
- Firestore receipts document fields: `storeName`, `totalAmount`, `date`, `time`, `category`, `rawText`, `items`, `timestamp`

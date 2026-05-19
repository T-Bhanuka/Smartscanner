# API Map — SmartScanner

This document maps network/Firebase/Storage/ML Kit integrations found in the `lib/` source.

- **Service:** Firebase Firestore
  - **Collection / Endpoint:** `receipts` (collection)
  - **Trigger:** `ReceiptRepository.addReceipt()` → calls `_publishReceiptToFirestore()` after local save
  - **Payload (JSON fields):**
    - `storeName` (String)
    - `totalAmount` / `total` (Number)
    - `date` (String)
    - `time` (String)
    - `category` (String, `Category.name`)
    - `rawText` (String)
    - `items` (Array of objects from `ReceiptItem.toJson()`)
    - `timestamp` (Number)
  - **Source:** `lib/services/receipt_repository.dart` (uses `FirebaseFirestore.instance.collection('receipts').add({...})`)

- **Service:** Local Storage (SharedPreferences)
  - **Keys:**
    - `_receiptsKey = 'receipt_app_pro_v5_data'` — stores JSON object: `{'receipts': [...], 'monthlyBudget': <number>}`
    - `_galleryKey = 'receipt_app_gallery_v5'` — stores JSON array of gallery image objects
  - **Triggers:** `StorageService.saveReceipts()`, `getAllReceipts()`, `getMonthlyBudget()`, `saveGalleryImage()`, `deleteGalleryImage()`
  - **Payload Shapes:**
    - Receipt JSON: matches `Receipt.toJson()` (fields: `id`, `storeName`, `date`, `time`, `items`, `total`, `category`, `timestamp`, `rawText`, `galleryImageId`)
    - Gallery image JSON: matches `GalleryImage.toJson()` (fields: `id`, `base64`, `timestamp`, `isProcessed`, `linkedReceiptId`)
  - **Source:** `lib/services/storage_service.dart`

- **Service:** Google ML Kit — Text Recognition
  - **Library / Class:** `google_mlkit_text_recognition` → `TextRecognizer(script: TextRecognitionScript.latin)`
  - **Trigger:** `ReceiptProcessingService.processReceiptImage(String imagePath)`
  - **Input:** `InputImage.fromFilePath(imagePath)`
  - **Output Used:** `recognizedText.text` (full OCR text) → stored as `rawText` on `Receipt`
  - **Notes (implementation):** recognizer closed after use (`textRecognizer.close()`)
  - **Source:** `lib/services/receipt_processing_service.dart`

- **Service:** Google ML Kit — Entity Extraction
  - **Library / Class:** `google_mlkit_entity_extraction` → `EntityExtractor(language: EntityExtractorLanguage.english)`
  - **Trigger:** Same as Text Recognition: `ReceiptProcessingService.processReceiptImage()`
  - **Input:** raw OCR text (`fullText`)
  - **Behavior / Payload:** `entityExtractor.annotateText(fullText)` returns annotations. Implementation inspects entities for:
    - `EntityType.money` — parses numeric amounts, selects largest as `total`
    - `EntityType.dateTime` — may override `date`
  - **Source:** `lib/services/receipt_processing_service.dart`

- **Service:** Gemini (Generative Language API via HTTP)
  - **Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey`
  - **Trigger:** `GeminiService.analyzeReceipt(String base64Image)` (manual call in code; service exists in `lib/services/gemini_service.dart`)
  - **Request Method / Headers:** `POST`, `Content-Type: application/json`
  - **Request Payload:** JSON body containing `contents` (prompt text + `inlineData` with `mimeType: 'image/jpeg'` and `data: base64Image`) and `generationConfig` requesting `responseMimeType: 'application/json'` and a response schema (expects fields like `isReadable`, `storeName`, `date`, `time`, `total`, `category`, `items` array with `name`, `price`, `category`).
  - **Response Handling:** Expects 200; parses `body['candidates'][0]['content']['parts'][0]['text']` as JSON
  - **Source:** `lib/services/gemini_service.dart`

- **Config:** Firebase Storage Bucket
  - **Value:** `receptscanner-2878a.firebasestorage.app` (present in `lib/firebase_options.dart`)
  - **Notes:** Bucket configured in `firebase_options.dart` but no direct `FirebaseStorage` API usage found in `lib/`.

- **Network Libraries Observed:**
  - `package:http/http.dart` used by `GeminiService` for POST requests
  - No other external HTTP endpoints found in `lib/` besides the Gemini endpoint

- **Where These Are Called / Triggers in App Flow:**
  - Receipt processing (camera/gallery) → `ReceiptProcessingService.processReceiptImage()` (ML Kit OCR + entity extraction) → constructs `Receipt` object
  - Saving a processed receipt → `ReceiptRepository.addReceipt()` → saves locally via `StorageService.saveReceipts()` and publishes to Firestore via `_publishReceiptToFirestore()`
  - Gallery image lifecycle → `StorageService.saveGalleryImage()` / `deleteGalleryImage()`
  - Gemini analysis is available via `GeminiService.analyzeReceipt()` but is not automatically invoked by repository/service code (implement as optional enhancement)

Files referenced:
- `lib/services/receipt_repository.dart`
- `lib/services/storage_service.dart`
- `lib/services/receipt_processing_service.dart`
- `lib/services/gemini_service.dart`
- `lib/types.dart`
- `lib/firebase_options.dart`


If you'd like, I can:
- Add direct code links to the specific lines for each mapping, or
- Run a quick pass to find any other network/third-party usages (e.g., analytics, crash reporting) across the repo.

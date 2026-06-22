# Technical Debt & Refactoring Plan

This document outlines the current technical debt and remediation roadmap for the SmartScanner Pro frontend application based on the actual REST API client architecture.

---

## Identified Technical Debt

### 1. Monolithic State Controller in `main.dart`
*   **Issue:** `_HomePageState` manages tab selections, image captures, compression, REST API requests, silent re-authentication, budget update modals, and deletion flows.
*   **Consequence:** High code complexity, low testability, and a risk of side effects during modifications.

### 2. Dead Code Scaffolding
*   **Issue:** The codebase contains unused files (`AppState`, `ReceiptRepository`, `ReceiptProcessingService`, `GeminiService`) and inactive dependencies (`google_mlkit_text_recognition`, `google_mlkit_entity_extraction`) that complicate onboarding.
*   **Consequence:** Developer confusion and increased app bundle size.

### 3. Lack of Offline Cache
*   **Issue:** The application relies entirely on network requests to display receipts and gallery images. If the network drops or a request fails, the app has no offline cache.
*   **Consequence:** Poor user experience when offline or on unstable networks.

### 4. Bypassed Backend Analytics
*   **Issue:** The REST backend provides robust analytical endpoints (`/analytics/*`), but the frontend aggregates calculations manually inside the `Dashboard` widget build method.
*   **Consequence:** Inefficient computation on every widget rebuild and data inconsistency between client and server.

### 5. Placeholder Test Suite
*   **Issue:** `test/widget_test.dart` is a placeholder that tests a counter and fails to run on the actual project.
*   **Consequence:** No regression protection for core flows.

---

## Remediation Roadmap

### Phase 1 — Codebase Cleanup
*   Remove unused files (`app_state.dart`, `receipt_repository.dart`, `receipt_processing_service.dart`, `gemini_service.dart`).
*   Remove unused ML Kit dependencies from `pubspec.yaml`.
*   Clean up commented-out code in `storage_service.dart`.

### Phase 2 — Refactor main.dart Monolith
*   Extract screen widgets (DashboardTab, VaultTab, ArchiveTab) into dedicated files.
*   Abstract image compression and base64 encoding out of the UI controller.
*   Implement a clean service locator (e.g., GetIt) for `ApiService` and `StorageService`.

### Phase 3 — Offline Synchronization & Caching
*   Enable local caching for budget, receipts list, and gallery records using local databases (e.g., Hive or SQLite).
*   Add automatic sync mechanisms when the app reconnects to the network.

### Phase 4 — Analytics Alignment
*   Wire the frontend Dashboard to fetch aggregated insights directly from `/analytics/trends` and `/analytics/insights/categories`.

### Phase 5 — Testing Suite Setup
*   Implement unit tests for `Receipt` and `GalleryImage` JSON serialization.
*   Add widget tests for login inputs, registration formats, and budget modal updates.

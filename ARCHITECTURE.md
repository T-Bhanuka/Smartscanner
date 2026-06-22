# SmartScanner Pro Architecture

This document describes the actual architecture, component relationships, layer boundaries, and file responsibilities verified in the codebase.

---

## Pattern Overview

The application is structured as a **Remote-First Client-Server Architecture** using standard Flutter `StatefulWidget` widgets and local `setState()` calls for presentation state management.

```
┌────────────────────────────────────────────────────────┐
│                      FRONTEND                          │
│                                                        │
│   ┌────────────────────────────────────────────────┐   │
│   │                 UI Layer                       │   │
│   │  (Screens, Navigation, fl_chart Rendering)     │   │
│   └──────────────────────┬─────────────────────────┘   │
│                          │                             │
│                          ▼ (REST API Service Call)     │
│   ┌────────────────────────────────────────────────┐   │
│   │               Service Layer                    │   │
│   │       (ApiService, StorageService)             │   │
│   └────────────────────────────────────────────────┘   │
└──────────────────────────┬─────────────────────────────┘
                           │ (HTTP REST Requests / JWT)
                           ▼
┌────────────────────────────────────────────────────────┐
│                      BACKEND                           │
│                                                        │
│         ┌──────────────────────────────────┐           │
│         │     Node.js / Express Server     │           │
│         └────────────────┬─────────────────┘           │
│                          │                             │
│            ┌─────────────┴─────────────┐               │
│            ▼                           ▼               │
│   ┌─────────────────┐         ┌─────────────────┐      │
│   │   MongoDB DB    │         │   Gemini API    │      │
│   └─────────────────┘         └─────────────────┘      │
└────────────────────────────────────────────────────────┘
```

### 1. Presentation Layer
*   Files: `lib/main.dart`, `lib/screens/auth/`
*   Responsibilities:
    *   Directly handles page routing, input verification, dialog popups, and tab navigation.
    *   Holds app state (`receipts`, `galleryImages`, `monthlyBudget`, and loading/error states) in `_HomePageState` and mutates it via `setState`.

### 2. Service Layer
*   Files: `lib/services/api_service.dart`, `lib/services/storage_service.dart`
*   Responsibilities:
    *   [ApiService](lib/services/api_service.dart) builds REST requests, processes JSON bodies, and runs REST commands.
    *   [StorageService](lib/services/storage_service.dart) caches the JWT authentication string in SharedPreferences (`jwt_token` key).

### 3. Domain Models
*   Files: `lib/types.dart`
*   Responsibilities:
    *   Defines core typed models `Receipt`, `ReceiptItem`, and `GalleryImage`.
    *   Handles data parsing, serializing, and mapping fields returned by the backend database.

---

## Technical Data Streams

### Receipt Scan & Processing Flow
1.  User starts camera scan in [CameraScanner](lib/components/camera_scanner.dart).
2.  On image capture, the file path is forwarded to `_processReceipt` in `_HomePageState` ([main.dart](lib/main.dart)).
3.  The image is resized to 800px width and compressed to 75% quality using the `image` library, then encoded as a base64 string.
4.  The frontend invokes [ApiService.analyzeReceipt](lib/services/api_service.dart#L116), posting the base64 string to the backend `/receipts/analyze` API route.
5.  The backend server invokes Gemini API to extract receipts data, saves it directly into the MongoDB collection, and returns the response.
6.  The frontend uploads the base64 image to `/gallery/upload` linked to the receipt ID, then invokes `_loadData()` to refetch all receipts from `/receipts`, rebuilding the UI state via `setState`.

---

## Architectural Boundary Rules

1.  **Direct API Access:** The presentation layer directly calls `ApiService` static methods (e.g. `ApiService.login`, `ApiService.getAllReceipts`) to fetch or manipulate remote data.
2.  **Unused Files / Legacy Scaffold:**
    *   `AppState` in [app_state.dart](lib/view_models/app_state.dart) is dead code. Do not use, reference, or import it.
    *   [ReceiptRepository](lib/services/receipt_repository.dart) is dead code and is bypassed entirely.
    *   [ReceiptProcessingService](lib/services/receipt_processing_service.dart) (local ML Kit OCR) is dead code and is bypassed.
    *   [GeminiService](lib/services/gemini_service.dart) (direct frontend Gemini integration) is dead code.
3.  **Local vs. Remote Data:**
    *   SharedPreferences is **only** used for auth token persistence.
    *   The Node.js Express server is the single source of truth for receipts, budgets, and gallery lists.

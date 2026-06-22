# SmartScanner Pro

SmartScanner Pro is a Flutter-based mobile application that enables users to scan receipts, track discretionary and business expenses, and visualize spending against a monthly budget.

## Core Features
*   **Secure Authentication:** User registration and login utilizing JWT authentication tokens.
*   **AI-Powered Receipt Scanning:** Captures receipt images using the device camera or imports from the gallery, resizes/compresses the image, and analyzes the receipt using the server-side Gemini API.
*   **Interactive Analytics Dashboard:** Visualizes spending trends and category distributions using `fl_chart` charts.
*   **Image Vault:** Stores scanned receipt images locally in base64 format and uploads them to the remote server.
*   **Budgeting:** Set and manage monthly spending budgets with immediate budget utilization bars.

---

## Actual System Architecture

Unlike historical design blueprints, the application runs on a **remote-first REST backend architecture**:

```
                  ┌──────────────────────┐
                  │     Flutter App      │
                  └──────────┬───────────┘
                             │ (REST / JSON / JWT)
                             ▼
                  ┌──────────────────────┐
                  │ Node.js/Express API  │
                  └──────────┬───────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   ┌─────────────────┐               ┌─────────────────┐
   │   MongoDB DB    │               │   Gemini API    │
   │ (Data Storage)  │               │ (AI Extraction) │
   └─────────────────┘               └─────────────────┘
```

1.  **State Management:** Managed via standard `StatefulWidget` state controllers and inline `setState()` updates inside [lib/main.dart](lib/main.dart).
2.  **Network Client:** Integrates with the Express API (running by default at `http://192.168.1.11:3005/api`) using the `http` package, carrying JWT headers.
3.  **Local Storage:** `SharedPreferences` is exclusively active for caching the JWT token. Receipt lists, budgets, and gallery images are retrieved from and saved to the remote database.
4.  **AI & OCR Analysis:** The frontend encodes compressed images to base64 and POSTs them to the backend `/receipts/analyze` route. The backend requests Gemini extraction, parses the details, and returns/saves the structured expense.

---

## Tech Stack
*   **Flutter & Dart SDK** (v3.11.5+)
*   **StatefulWidget & setState()** (State Management)
*   **http** (REST API integrations)
*   **shared_preferences** (Auth token cache)
*   **fl_chart** (Dashboard data visualization)
*   **camera & image_picker** (Picture capturing and gallery selection)
*   **image** (Image resizing and compression helpers)

---

## Folder Map

*   `lib/main.dart` — Root entry point, theme declaration, named route table, and HomePage state control.
*   `lib/screens/auth/` — Login and registration input views.
*   `lib/components/dashboard.dart` — Local calculations and drawing of charts.
*   `lib/components/camera_scanner.dart` — Camera preview controls.
*   `lib/services/api_service.dart` — API requests mapping.
*   `lib/services/storage_service.dart` — Active token store.
*   `lib/types.dart` — Receipt, ReceiptItem, and GalleryImage data models.
*   `docs/v2/` — Official, up-to-date documentation guides.
*   `docs/archive/` — Outdated design records kept for reference.

---

## Getting Started

### Prerequisites
*   Ensure Flutter SDK (v3.11.5+) is installed.
*   The Express backend server must be running and accessible over your local network.

### Setup Instructions
1.  Verify the backend server URL in [lib/services/api_service.dart](lib/services/api_service.dart#L10) and [lib/services/gemini_service.dart](lib/services/gemini_service.dart#L9) matches your computer's network IP (e.g., `http://192.168.1.11:3005/api`).
2.  Run `flutter pub get` to download dependencies.
3.  Connect a physical device or emulator.
4.  Run `flutter run` to launch the application.
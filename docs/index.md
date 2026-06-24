# Smartscanner Developer Wiki

Welcome to the internal documentation for Smartscanner, a Flutter application that scans receipts using on-device machine learning and stores expense data in Firebase.

## Architecture

*   **Frontend**: Flutter (Dart)
*   **Storage**: Firebase Cloud Firestore
*   **ML Engine**: Google ML Kit (Text Recognition + Entity Extraction)

## Core ML Pipeline

The receipt processing pipeline is primarily orchestrated within `_processReceipt` in `lib/main.dart` (and abstractable via `ReceiptProcessingService`):

1.  **Capture**: The user captures an image using the `CameraScanner` widget or selects one from the gallery.
2.  **Text Recognition**: The `TextRecognizer` (ML Kit) extracts all raw text from the image.
3.  **Entity Extraction**: The `EntityExtractor` (ML Kit) parses the text to find semantic entities, specifically `EntityType.money` (to find the total amount) and `EntityType.dateTime` (to determine the receipt date).
4.  **Persistence**: The extracted `storeName` (typically the first line of text), `totalAmount`, and `date` are saved to Firestore, allowing for cross-device sync.

## Key Components

*   **`lib/main.dart`**: The application entry point and root widget. It contains the `HomePage` which manages the tabbed navigation (Dashboard, Vault, Archive), Fab state, and the receipt processing pipeline.
*   **`lib/components/dashboard.dart`**: A statistics dashboard visualizing total expenses vs monthly budget, daily spending trends via a bar chart, and category distribution via a pie chart.
*   **`lib/components/camera_scanner.dart`**: A full-screen camera view providing a custom viewfinder overlay and capture functionality.
*   **`lib/services/storage_service.dart`**: A utility class utilizing `shared_preferences` to fetch and persist local preferences and cached data (e.g., monthly budget, local gallery images).
*   **`lib/services/receipt_processing_service.dart`**: Abstraction for future enhancements or alternative ML providers (like Gemini).

## Getting Started

1.  Ensure you have Flutter installed and configured.
2.  Run `flutter pub get` to install dependencies.
3.  Run the app via `flutter run`.

## Code Quality

All core components and services are documented with standard Dart docstrings (`///`). Run `flutter analyze` to ensure code quality and adherence to style guides.

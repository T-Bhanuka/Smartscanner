# Smartscanner

Smartscanner is a Flutter mobile app for scanning receipts, extracting totals/details, tracking spending, and managing a monthly budget.

## Features

- Scan receipts using the camera
- Import receipt images from gallery
- OCR-based receipt text extraction (Google ML Kit)
- Receipt history and gallery history
- Monthly budget tracking with dashboard visualization
- Local persistence (SharedPreferences) and Firestore publishing for scanned receipts

## Tech Stack

- Flutter / Dart
- Firebase Core + Cloud Firestore
- Provider state management
- Google ML Kit (Text Recognition + Entity Extraction)
- SharedPreferences

## Project Structure

```text
lib/
  main.dart                    # App entry and HomePage shell
  types.dart                   # Domain models (Receipt, ReceiptItem, GalleryImage)
  components/                  # Reusable UI widgets (dashboard, camera scanner)
  view_models/app_state.dart   # UI state + user actions
  services/
    receipt_processing_service.dart  # OCR + basic receipt extraction
    receipt_repository.dart          # Persistence + Firestore publishing
    storage_service.dart             # SharedPreferences storage
    gemini_service.dart              # Optional AI analysis service
```

## Getting Started

### Prerequisites

- Flutter SDK (3.x)
- Dart SDK (bundled with Flutter)
- Android Studio or Xcode for device/emulator setup
- Firebase project configured for this app

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

## Firebase Setup

The project uses generated Firebase options from `lib/firebase_options.dart`.

If you need to reconfigure Firebase for your environment:

1. Install FlutterFire CLI
2. Run `flutterfire configure`
3. Ensure platform files are updated (`android/`, `ios/`, etc.)

## Development Checks

```bash
flutter analyze
flutter test
```

## Notes

- `lib/services/gemini_service.dart` includes a placeholder API key (`YOUR_API_KEY_HERE`).
- Do not commit real API keys or secrets to the repository.

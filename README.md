# SmartScanner

SmartScanner is a Flutter-based receipt scanning and expense tracking app. The app uses camera capture or gallery import, OCR, local persistence, Firebase, and charting to show spending patterns and archived receipts.

## Overview

The current codebase is organized around MVVM with Provider:

- UI layer in `lib/main.dart` and `lib/components/`
- ViewModel in `lib/view_models/app_state.dart`
- Services in `lib/services/`
- Shared models in `lib/types.dart`

The app is functional, but several integration points are still incomplete or intentionally experimental. The most important known issue is that local persistence and Firestore writes are not yet aligned into one consistent source of truth.

## Tech Stack

- Flutter and Dart 3.11.5
- Provider for state management
- Firebase Core and Cloud Firestore
- Camera and Image Picker for capture/import
- SharedPreferences for local persistence
- Google ML Kit text recognition and entity extraction for OCR
- HTTP for external AI/API calls
- fl_chart for analytics and budget visualization
- intl for date and number formatting
- path_provider and image for file handling and image processing helpers

## Architecture Summary

The app is structured as a layered client application:

1. User actions start in the UI.
2. UI delegates state changes to `AppState`.
3. `AppState` coordinates services and updates listeners.
4. Services handle OCR, local storage, and backend integration.
5. Shared models move between layers without UI-specific logic.

For the detailed boundary rules, see [ARCHITECTURE.md](ARCHITECTURE.md).

## File Map

### Core App Files

- `lib/main.dart` - App entry point, Firebase initialization, Provider wiring, tab navigation, scan flow UI, budget dialog, gallery/history views, and orchestration logic.
- `lib/types.dart` - Shared domain models and enums, including `Receipt`, `ReceiptItem`, `GalleryImage`, and `Category`.
- `lib/view_models/app_state.dart` - App state controller for receipts, gallery images, loading flags, errors, and budget updates.

### UI Components

- `lib/components/dashboard.dart` - Analytics dashboard with budget summary, trend chart, and category breakdown.
- `lib/components/camera_scanner.dart` - Camera capture screen used for receipt scanning.

### Services

- `lib/services/storage_service.dart` - SharedPreferences persistence for receipts, gallery images, and budget values.
- `lib/services/receipt_repository.dart` - Repository wrapper that coordinates storage operations and Firestore publishing.
- `lib/services/receipt_processing_service.dart` - OCR pipeline using ML Kit text recognition and entity extraction.
- `lib/services/gemini_service.dart` - Experimental AI extraction service, currently implemented but not integrated into the main flow.

### Tests

- `test/widget_test.dart` - Default Flutter template test; currently does not exercise the SmartScanner scan, storage, or analytics flows.

## Platform and Configuration Files

- `pubspec.yaml` - Flutter package metadata, SDK version, and dependency list.
- `analysis_options.yaml` - Linting rules based on Flutter lints.
- `firebase.json` - FlutterFire project configuration.
- `lib/firebase_options.dart` - Generated Firebase platform configuration.
- `android/app/build.gradle.kts` - Android app build settings and Google services plugin setup.
- `android/gradle.properties` - Android build configuration and memory settings.
- `android/app/google-services.json` - Firebase Android configuration.
- `ios/Runner/Info.plist` - iOS app metadata and permission configuration.
- `ios/Runner/AppDelegate.swift` - Standard Flutter iOS entry point.
- `web/index.html` and `web/manifest.json` - Web shell and PWA metadata.
- `windows/`, `linux/`, and `macos/` - Desktop platform runners and generated Flutter build scaffolding.

## Documentation Files

- `ARCHITECTURE.md` - Layering, boundaries, and repository layout.
- `PLAN.md` - Known risks, technical debt, and staged remediation plan.
- `docs/adr/0001-mvvm-via-provider.md` - Decision to use MVVM with Provider.
- `docs/adr/0002-service-layer-boundaries.md` - Decision to keep business logic and integrations inside services.
- `docs/adr/0003-adr-process.md` - Process for recording future architecture decisions.
- `ios/specs/receipt_processing_rules.md` - Detailed receipt-processing logic and persistence rules.

## Current Limitations

These are the main decision-relevant gaps in the current codebase:

- Receipt writes are published to Firestore, but the UI primarily reads from local storage.
- `gemini_service.dart` exists but is not wired into the default scan flow.
- Gallery persistence is present, but the end-to-end gallery workflow is only partially integrated.
- `test/widget_test.dart` still reflects the default Flutter template instead of the real app.
- iOS privacy permissions should be verified before shipping camera/photo features.

## Development Notes

- Keep UI changes in the presentation layer and avoid direct persistence calls from widgets.
- Route new business logic through services and the repository layer.
- Record architecture changes in `docs/adr/` before changing layering or persistence strategy.
- Treat `PLAN.md` as the active technical debt list until the data flow is unified.

## Getting Started

Use the standard Flutter workflow for local development:

1. Install Flutter and ensure the project uses Dart 3.11.5.
2. Run `flutter pub get`.
3. Configure Firebase for each target platform if you are changing backend behavior.
4. Launch the app with `flutter run` on the desired device or simulator.

If you are extending the app, review `ARCHITECTURE.md` first so new code stays aligned with the existing MVVM boundaries.
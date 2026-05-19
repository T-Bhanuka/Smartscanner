# SmartScanner Architecture

## Pattern

SmartScanner uses MVVM with Provider.

The architecture is intentionally simple:

- UI owns rendering and interaction only.
- ViewModel owns state transitions and orchestration.
- Services own storage, OCR, and external integrations.
- Domain models define shared contracts.

## Layers and Responsibilities

### UI Layer

- [lib/main.dart](lib/main.dart)
- [lib/components](lib/components)

Responsibilities:

- Render the app shell, tabs, dialogs, scanner modal, and dashboards.
- Forward user actions into `AppState`.
- Avoid direct access to Firestore, SharedPreferences, ML Kit, or HTTP APIs.

### ViewModel Layer

- [lib/view_models/app_state.dart](lib/view_models/app_state.dart)

Responsibilities:

- Own UI state such as receipts, gallery images, loading flags, errors, and budget.
- Call services and map results into state updates.
- Notify listeners when state changes.

### Service Layer

- [lib/services/storage_service.dart](lib/services/storage_service.dart)
- [lib/services/receipt_repository.dart](lib/services/receipt_repository.dart)
- [lib/services/receipt_processing_service.dart](lib/services/receipt_processing_service.dart)
- [lib/services/gemini_service.dart](lib/services/gemini_service.dart)

Responsibilities:

- Persist and retrieve local app data.
- Bridge between local storage and Firestore.
- Run OCR and entity extraction.
- Keep external API and infrastructure details out of the UI.

### Domain Models

- [lib/types.dart](lib/types.dart)

Responsibilities:

- Define `Receipt`, `ReceiptItem`, `GalleryImage`, and `Category`.
- Provide serialization contracts shared across layers.
- Remain independent of widgets, storage, and API clients.

## File Responsibilities

### Application Entry and Shell

- [lib/main.dart](lib/main.dart) bootstraps Firebase, installs the Provider tree, and hosts the home screen.
- It also coordinates receipt scanning, gallery selection, deletion dialogs, budget editing, and tab navigation.
- Current risk: it is still the largest file and mixes presentation with orchestration logic.

### State Management

- [lib/view_models/app_state.dart](lib/view_models/app_state.dart) controls the state the UI consumes.
- It loads receipts and images, invokes receipt processing, saves data through the repository, and updates listeners.
- Current risk: state is still broad and will likely need splitting as features grow.

### Persistence and Integrations

- [lib/services/storage_service.dart](lib/services/storage_service.dart) serializes receipts, gallery images, and budget values into SharedPreferences.
- [lib/services/receipt_repository.dart](lib/services/receipt_repository.dart) is the coordination point between local storage and Firestore.
- [lib/services/receipt_processing_service.dart](lib/services/receipt_processing_service.dart) extracts receipt data from OCR text and ML Kit entities.
- [lib/services/gemini_service.dart](lib/services/gemini_service.dart) contains an alternative extraction path that is not currently wired into the main flow.

### UI Components

- [lib/components/camera_scanner.dart](lib/components/camera_scanner.dart) handles receipt capture from the camera.
- [lib/components/dashboard.dart](lib/components/dashboard.dart) computes and renders analytics for spending and category distribution.

## Data Flow

1. User triggers scan, gallery import, delete, or budget update in the UI.
2. UI calls an `AppState` method.
3. `AppState` coordinates one or more services.
4. Services read or write local storage, Firestore, or ML Kit integrations.
5. `AppState` updates its state and calls `notifyListeners()`.
6. UI rebuilds from the updated state.

## Boundary Rules

1. UI -> ViewModel only.
- Allowed: `context.watch<AppState>()`, `context.read<AppState>()`.
- Not allowed: calling Firestore, SharedPreferences, or OCR APIs directly from widgets.

2. ViewModel -> Services only.
- Allowed: orchestrating service calls and mapping results into state.
- Not allowed: direct persistence or API wiring in the ViewModel.

3. Services -> data and external systems only.
- Allowed: Firestore, SharedPreferences, ML Kit, and HTTP APIs.
- Not allowed: imports from UI widgets or `AppState`.

4. Models remain shared contracts.
- Keep all serializable data structures in [lib/types.dart](lib/types.dart).

## Repository Layout

- [lib/main.dart](lib/main.dart)
- [lib/components](lib/components)
- [lib/view_models](lib/view_models)
- [lib/services](lib/services)
- [lib/types.dart](lib/types.dart)
- [docs/adr](docs/adr)
- [ios/specs/receipt_processing_rules.md](ios/specs/receipt_processing_rules.md)

## Current Architectural Risks

- Firestore writes and local reads are not yet unified.
- `main.dart` is still a monolith and needs further slicing.
- OCR is constrained by Latin-script recognition and English entity extraction.
- The Gemini service exists but is not part of the default runtime path.
- Dashboard aggregation currently performs work during widget build time.

## Rules for New Work

- Preserve the UI -> ViewModel -> Services direction.
- Add an ADR in [docs/adr](docs/adr) before changing layering, persistence strategy, or state ownership.
- Update this file whenever a boundary changes.
- Treat [PLAN.md](PLAN.md) as the living technical-debt tracker until the broken data flow is fixed.

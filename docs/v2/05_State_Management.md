# State Management Architecture

SmartScanner Pro utilizes a local component state model based on standard Flutter `StatefulWidget` and `setState` blocks.

## State Ownership (HomePage)

State properties are managed inside `_HomePageState` in [lib/main.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart):
*   `List<Receipt> receipts` — Active list of receipts fetched from the backend.
*   `List<GalleryImage> galleryImages` — Base64 images for the Vault tab.
*   `double monthlyBudget` — Current month's budget configuration.
*   `bool showScanner` — Flags visibility of the `CameraScanner` preview overlay.
*   `bool isAnalyzing` — Triggers the fullscreen scanning spinner block.
*   `int activeTab` — Index of the selected tab view.
*   `String? analysisError` — Store error string to display in notifications.

## State Lifecycle
*   **Initialization (`initState`):** Triggers `_loadData()` to load cached tokens and query backend data.
*   **Data Mutations:** UI events call REST endpoints in `ApiService` asynchronously and call `setState` upon response.
*   **Rebuild Trigger:** Calling `setState` triggers component rebuilds, updating widgets like the `Dashboard` and lists.

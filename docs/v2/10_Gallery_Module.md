# Gallery Module

The Gallery Module displays scanned receipt images in the Vault.

## Vault Layout View
*   **Widget:** `_buildGalleryTab()` ([main.dart:L615](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart#L615)).
*   **Grid:** A dynamic `GridView.builder` showing two columns of preview cards.

## Base64 Image Rendering
Images are stored on the server and loaded as Base64 strings. The frontend decodes the base64 payload on the fly using `_buildGalleryImage()` ([main.dart:L699](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart#L699)):
*   Strip metadata headers (e.g. `data:image/jpeg;base64,`).
*   Run `base64Decode(cleanString)`.
*   Render inside `Image.memory` using a `ClipRRect` to match the border curves of the card UI.

## Delete Pipeline
*   Deleting an item triggers `_deleteGalleryItem(id)` ([main.dart:L340](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart#L340)).
*   Updates local UI state via `setState`.
*   Sends a DELETE request to the server `/gallery/:id` route.

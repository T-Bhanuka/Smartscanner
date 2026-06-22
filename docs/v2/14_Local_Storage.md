# Local Storage

SmartScanner Pro utilizes `SharedPreferences` for local key-value caching.

## Cache Configurations

*   **Plugin:** `shared_preferences`
*   **Encrypted:** No (values are stored in plaintext XML on Android and plist on iOS).

## Active Key Allocations

*   **`jwt_token` (String):** Caches the JSON Web Token string returned by `/auth/login` or `/auth/register` endpoints.

## Legacy / Unused Key Keys
The following keys are defined in [StorageService](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/storage_service.dart#L7) but are inactive in the production flow:
*   `receipt_app_pro_v5_data` (storing receipt lists and budget configurations).
*   `receipt_app_gallery_v5` (storing local gallery images array).

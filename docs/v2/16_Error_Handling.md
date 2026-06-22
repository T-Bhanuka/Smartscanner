# Error Handling

SmartScanner Pro handles errors to prevent crashes and guide users when operations fail.

## 1. Alert Banners & Snackbars
*   **Sign-in Failures:** Login errors (e.g. invalid password) are caught in `LoginScreen._performLogin` and displayed in red snackbars ([login_screen.dart:L40](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/screens/auth/login_screen.dart#L40)).
*   **Scanning Failures:** Failures in `_processReceipt` are caught and displayed in a warning banner in `HomePage` ([main.dart:L473](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart#L473)).

## 2. Automatic Re-Authentication (401 Response Codes)
If a request fails with an HTTP `401 Unauthorized` status code (indicating an expired or invalid token), the application attempts to re-authenticate silently:
1.  Catches the 401 status code in `HomePage._loadData` ([main.dart:L113](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart#L113)).
2.  Clears the current token cache: `StorageService.clearToken()`.
3.  Attempts silent background registration or login: `_performSilentAuth()`.
4.  Retries the original data fetch request (`_fetchData()`).

## 3. Network Failure Fallbacks
Methods like `_compressAndEncodeImage` implement safety checks. If image compression fails, the app falls back to encoding the raw, uncompressed bytes instead of crashing.

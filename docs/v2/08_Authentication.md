# Authentication Integration

SmartScanner Pro enforces JWT-based session security across all data operations.

## Authentication Interface Views

*   **[LoginScreen](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/screens/auth/login_screen.dart):** Validates email and password parameters and calls `ApiService.login`. Saves the token in cache and routes to the dashboard.
*   **[RegisterScreen](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/screens/auth/register_screen.dart):** Uses standard form validations (Regex patterns for emails, length limit rules) and calls `ApiService.register`.

## Silent Background Auto-Auth

To optimize developer testing, a silent auto-auth sequence runs on app launch if no cached token is detected:

```dart
Future<void> _performSilentAuth() async {
  try {
    // Attempt registration first
    await ApiService.register('User', 'user@example.com', 'password123');
  } catch (e) {
    // If user already exists, perform standard login
    await ApiService.login('user@example.com', 'password123');
  }
}
```

## JWT Token Caching
Tokens are cached inside SharedPreferences using the key `jwt_token` via [StorageService](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/storage_service.dart).

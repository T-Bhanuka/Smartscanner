# Integration Guide

This guide details configuring, running, and debugging network connectivity between the Flutter frontend app and the Node.js Express server.

---

## 1. Network Endpoint Configuration

Since the app runs on emulators or physical test devices, using `localhost` directly will cause connections to fail. The app must route to the developer computer's network-facing IP.

In [api_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/api_service.dart#L10) and [gemini_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/gemini_service.dart#L9), verify that `baseUrl` matches your machine's local IP address:

```dart
// Use Laptop's Wi-Fi IP (both laptop and phone must be on the same Wi-Fi)
static const String baseUrl = 'http://192.168.1.11:3005/api';
```

---

## 2. JWT Token & Session Interceptor

1.  **Storage:** Upon successful `/auth/login` or `/auth/register` API calls, the frontend receives a token and caches it:
    ```dart
    await StorageService.saveToken(response['token']);
    ```
2.  **Request Decoration:** All authenticated client requests to endpoints in [api_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/api_service.dart#L12) call a private handler to inject the token into headers:
    ```dart
    final token = await StorageService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    ```

---

## 3. Silent Authentication Flow

To enable quick runtime debugging, `HomePage._loadData` checks for an existing JWT token on startup. If no token is cached, it invokes a silent registration or fallback login script:

```dart
Future<void> _performSilentAuth() async {
  try {
    // Attempt registration
    await ApiService.register('User', 'user@example.com', 'password123');
  } catch (e) {
    // Fallback login
    await ApiService.login('user@example.com', 'password123');
  }
}
```

---

## 4. Troubleshooting Network Failures

*   **SocketException:** The mobile device cannot ping the server IP.
    *   *Fix:* Verify that the mobile device and server host are on the exact same Wi-Fi subnet.
*   **401 Unauthorized:** The JWT token is invalid or expired.
    *   *Fix:* The app catches 401 response codes in [main.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart#L113), clears the token using `StorageService.clearToken()`, runs the silent auto-auth sequence, and automatically retries the failed data fetch request.

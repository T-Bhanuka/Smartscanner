# API Integration

The frontend integrates with the backend API via the [ApiService](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/api_service.dart) wrapper.

## Client Configuration

*   **HTTP Client:** `package:http/http.dart`
*   **Base URL:** Configured in `ApiService.baseUrl` (default: `http://192.168.1.11:3005/api`).

## Request Pipeline (`_makeRequest`)

All API calls route through the private helper `_makeRequest` to handle token injection, request formatting, and error parsing:

```dart
static Future<Map<String, dynamic>> _makeRequest(
  String method,
  String endpoint, {
  dynamic body,
  bool requiresAuth = true,
}) async {
  final url = Uri.parse('$baseUrl$endpoint');
  final headers = { 'Content-Type': 'application/json' };

  if (requiresAuth) {
    final token = await StorageService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
  }
  
  // Method mapping (GET, POST, PUT, DELETE) and HTTP parsing...
}
```

## Error Parsing Rules
*   Status codes in the `2xx` range return the decoded JSON body.
*   Other status codes try to parse an `{ "error": "description" }` JSON error body, throwing an `Exception` with the returned description.

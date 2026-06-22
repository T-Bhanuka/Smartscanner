# Backend Communication

The frontend mobile client communicates with the Node.js Express server using standard HTTP requests.

## Connection Configurations

*   **Endpoint Address:** `http://192.168.1.11:3005/api` (Verify this local IP matches your development machine).
*   **JSON Transport:** Payloads are serialized using `jsonEncode` and deserialized using `jsonDecode`.
*   **Request Headers:**
    *   `Content-Type: application/json`
    *   `Authorization: Bearer <JWT Token>` (for endpoints requiring auth)

## Network Timeouts
To handle slow mobile networks, requests include timeout limits. For example, `GeminiService.analyzeReceipt` sets a timeout duration of **90 seconds** ([gemini_service.dart:L33](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/gemini_service.dart#L33)).

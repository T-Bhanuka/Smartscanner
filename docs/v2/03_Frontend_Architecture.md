# Frontend Architecture

The frontend application is built using Flutter and Dart, organized as a simplified layered client that uses standard widgets for views and static services for backend communication.

## Layer Structure

### 1. Presentation Layer
Contains the user-facing layouts, input text controllers, navigation configurations, and local list states:
*   [main.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart): Sets up MaterialApp routing and implements the main `HomePage` tabs (`Analytics`, `Vault`, `Archive`).
*   [screens/auth/](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/screens/auth/): Contains `LoginScreen` and `RegisterScreen` form fields.

### 2. Service Layer
Provides static methods containing business logics and networking:
*   [api_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/api_service.dart): Encapsulates all REST requests and response mapping.
*   [storage_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/storage_service.dart): Manages JWT auth token keys inside SharedPreferences.

### 3. Shared Domain Models
*   [types.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/types.dart): Defines domain schemas `Receipt`, `ReceiptItem`, and `GalleryImage` with `fromJson` and `toJson` deserializers.

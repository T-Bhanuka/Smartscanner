# Developer Onboarding Guide

Follow these steps to set up the SmartScanner Pro mobile development environment.

---

## 1. Local Environment Setup

1.  **Flutter SDK Installation:** Download and install Flutter SDK (v3.11.5+).
2.  **Verify Setup:** Check for missing dependencies:
    ```bash
    flutter doctor
    ```
3.  **Clone Repository & Download Packages:**
    ```bash
    flutter pub get
    ```

---

## 2. API Server Configuration

To run the app, you need a local or remote instance of the Node.js Express server:
1.  Verify the backend server is running on your network (default port: `3005`).
2.  Update the network IP address in [api_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/api_service.dart#L10) and [gemini_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/gemini_service.dart#L9) to match your machine's network IP (e.g. `192.168.1.11`).

---

## 3. Launching the App
1.  Connect an Android/iOS device (enable USB Debugging) or start an emulator.
2.  Run the application:
    ```bash
    flutter run
    ```

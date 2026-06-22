# Troubleshooting Guide

This guide details resolutions for common compilation and runtime issues.

---

## 1. Network Connectivity Issues

### SocketException: Connection refused (or OS Error 111)
*   **Description:** The frontend app cannot connect to the backend server.
*   **Cause:**
    *   The app is attempting to connect to `localhost` or `127.0.0.1` (which resolves to the mobile device instead of the host machine).
    *   The backend IP address configured in the frontend is incorrect.
    *   The backend server is not running.
*   **Resolution:**
    1.  Ensure the Express server is running.
    2.  Find your computer's local IP address (using `ipconfig` on Windows or `ifconfig` on macOS/Linux).
    3.  Update the IP address in [api_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/api_service.dart#L10) and [gemini_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/gemini_service.dart#L9) to match your machine's local IP.
    4.  Ensure your mobile device is connected to the same Wi-Fi network as the host machine.

---

## 2. Compilation & Run Failures

### INSTALL_FAILED_UPDATE_INCOMPATIBLE
*   **Description:** ADB fails to install the application to your Android device with a signature mismatch error.
*   **Cause:** An existing app with the same package name (`com.example.first_project`) is already installed on the device but signed with a different signature.
*   **Resolution:**
    *   Uninstall the existing app from the device (ensure you uncheck "keep app data").
    *   Alternatively, run the following command to uninstall:
        ```bash
        adb uninstall com.example.first_project
        ```
    *   Run `flutter run` again.

### Camera Permission Crash (iOS only)
*   **Description:** The app crashes immediately upon accessing the camera or gallery.
*   **Cause:** Missing usage descriptions in `ios/Runner/Info.plist`.
*   **Resolution:** Add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` keys and descriptions to [Info.plist](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/ios/Runner/Info.plist) (see [19_Deployment_Guide.md](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/docs/v2/19_Deployment_Guide.md)).

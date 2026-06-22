# Deployment Guide

This guide details platform-specific configurations required to build and deploy SmartScanner Pro.

---

## Android Configuration

*   **Min SDK Target:** `21` (required for Google ML Kit compatibility).
*   **Compile SDK Target:** `34` (Android 14 API baseline).
*   **Configuration Files:**
    *   `android/app/build.gradle` — Houses version names, build numbers, and SDK settings.

---

## iOS Configuration

To prevent camera crashes on iOS, you must configure permission descriptions inside `ios/Runner/Info.plist`. Add the following keys inside `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>SmartScanner Pro requires camera access to scan receipt documents.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>SmartScanner Pro requires photo library access to import saved receipts.</string>
```

---

## Production Build Compilation Commands

Generate signed deployment bundles using the following commands:

*   **Android App Bundle:**
    ```bash
    flutter build appbundle --release
    ```
*   **iOS App Store Build:**
    ```bash
    flutter build ipa --release
    ```

# Receipt Module

The Receipt Module handles camera capture, image compression, base64 data transmission, and server-side OCR analysis.

## Camera Capture Interface

*   **Widget:** [CameraScanner](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/components/camera_scanner.dart)
*   **Controller:** `CameraController` (configured to `ResolutionPreset.medium`)
*   **Capabilities:** Toggles torch flash (`FlashMode.torch` vs `FlashMode.off`) and captures photos (`takePicture()`).

## Image Compression Pipeline

To ensure fast uploads, captured images are compressed before transport inside `_HomePageState._compressAndEncodeImage` ([main.dart:L222](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart#L222)):
1.  Read local file bytes.
2.  Decode image using the `image` library.
3.  If the image width exceeds 800px, resize it to 800px while maintaining the aspect ratio.
4.  Compress the resized image to 75% quality JPEG.
5.  Convert the compressed bytes to a Base64 string.

## Receipt Processing REST API
The base64 string is POSTed to the backend `/receipts/analyze` route. The backend requests Gemini extraction, parses the details, and returns the parsed `Receipt` JSON payload.

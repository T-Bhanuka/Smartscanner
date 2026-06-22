# Data Flow Mapping

This document traces data flows for key user actions.

## 1. User Login
```
[login_screen.dart]
  ↓ (User inputs credentials & clicks Login)
[ApiService.login(email, password)]
  ↓ (POST Request to /auth/login)
[StorageService.saveToken(token)] 
  ↓ (Persists token to SharedPreferences)
[Navigator.pushReplacementNamed('/dashboard')]
```

## 2. Receipt Scan & Analysis
```
[HomePage Floating Action Button]
  ↓ (User triggers scan -> shows CameraScanner)
[CameraScanner.takePicture()] 
  ↓ (Saves image to filepath)
[HomePage._processReceipt(filePath)]
  ↓ (Resizes to 800px, quality 75% -> base64)
[ApiService.analyzeReceipt(base64Image)]
  ↓ (POST Request to /receipts/analyze -> Backend calls Gemini API -> saves to MongoDB)
[ApiService.uploadImage(base64Image, receiptId)]
  ↓ (POST Request uploads image to /gallery/upload, linking receiptId)
[HomePage._loadData()]
  ↓ (Calls ApiService.getAllReceipts() & ApiService.getGalleryImages())
[setState()]
  ↓ (UI updates widgets with fresh backend list values)
```

# REST API Map

This document maps all REST network integrations implemented in [api_service.dart](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/api_service.dart) connecting to the backend server.

---

## Base Configuration

*   **URL:** `http://192.168.1.11:3005/api`
*   **Request Headers:**
    *   `Content-Type: application/json`
    *   `Authorization: Bearer <JWT Token>` (for endpoints requiring auth)

---

## Endpoints Mapping

### 1. User Authentication

#### POST `/auth/register`
*   **Trigger:** `ApiService.register(username, email, password)`
*   **Auth Required:** No
*   **Payload:** `{ "name": name, "email": email, "password": password }`
*   **Response:** `{ "token": "<JWT Token String>" }`

#### POST `/auth/login`
*   **Trigger:** `ApiService.login(email, password)`
*   **Auth Required:** No
*   **Payload:** `{ "email": email, "password": password }`
*   **Response:** `{ "token": "<JWT Token String>" }`

#### GET `/auth/profile`
*   **Trigger:** `ApiService.getProfile()`
*   **Auth Required:** Yes
*   **Response:** User account data dictionary object.

#### PUT `/auth/profile`
*   **Trigger:** `ApiService.updateProfile({name, monthlyBudget})`
*   **Auth Required:** Yes
*   **Payload:** `{ "name": name, "monthlyBudget": budget }`

---

### 2. Receipts & Scanning

#### POST `/receipts/analyze`
*   **Trigger:** `ApiService.analyzeReceipt(base64Image)`
*   **Auth Required:** Yes
*   **Payload:** `{ "imageData": "data:image/jpeg;base64,..." }`
*   **Response:** `{ "receipt": { "_id": "...", "storeName": "...", "total": 0.0, ... } }`

#### GET `/receipts`
*   **Trigger:** `ApiService.getAllReceipts({month, category, skip, limit})`
*   **Auth Required:** Yes
*   **Response:** `{ "receipts": [ { "_id": "...", "storeName": "...", "total": 45.5, ... } ] }`

#### PUT `/receipts/:id`
*   **Trigger:** `ApiService.updateReceipt(id, {category, tags, notes})`
*   **Auth Required:** Yes
*   **Payload:** `{ "category": "...", "tags": [], "notes": "..." }`

#### DELETE `/receipts/:id`
*   **Trigger:** `ApiService.deleteReceipt(id)`
*   **Auth Required:** Yes

---

### 3. Vault Gallery Images

#### POST `/gallery/upload`
*   **Trigger:** `ApiService.uploadImage(base64Image, {receiptId})`
*   **Auth Required:** Yes
*   **Payload:** `{ "imageData": "data:image/jpeg;base64,...", "receiptId": "..." }`

#### GET `/gallery`
*   **Trigger:** `ApiService.getGalleryImages({skip, limit})`
*   **Auth Required:** Yes
*   **Response:** `{ "images": [ { "_id": "...", "base64": "...", "timestamp": ... } ] }`

#### DELETE `/gallery/:id`
*   **Trigger:** `ApiService.deleteGalleryImage(id)`
*   **Auth Required:** Yes

---

### 4. Budgets

#### GET `/budget/:month`
*   **Trigger:** `ApiService.getBudget(month)` (format: `YYYY-MM`)
*   **Auth Required:** Yes
*   **Response:** `{ "budget": 20000.0 }`

#### PUT `/budget/:month`
*   **Trigger:** `ApiService.updateBudget(month, budget)`
*   **Auth Required:** Yes
*   **Payload:** `{ "budget": 20000.0 }`

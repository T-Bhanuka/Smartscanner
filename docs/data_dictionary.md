# Data Dictionary

This document defines the data models, serialization contracts, and variables verified in the codebase.

---

## Core Domain Models

### 1. Receipt
Represents an expense document analyzed by Gemini and saved to MongoDB.

| Field Name | Data Type | Nullable | Description / Constraints | Serialization Keys |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `String` | No | Unique MongoDB ID (`_id`) or fallback client string | `_id`, `id` |
| `storeName` | `String` | No | Extracted merchant name; default: `Unknown Store` | `storeName` |
| `date` | `String` | No | Extracted purchase date | `date` |
| `time` | `String` | No | Extracted time | `time` |
| `items` | `List<ReceiptItem>` | No | Item list; defaults to empty array | `items` |
| `total` | `double` | No | Extracted amount; defaults to `0.0` | `total` |
| `category` | `Category` | No | Expense classification; defaults to `Category.Other` | `category` (stored as name) |
| `timestamp` | `int` | No | Unix milliseconds of receipt generation | `timestamp`, `createdAt` |
| `galleryImageId` | `String?` | Yes | Linked image reference ID | `galleryImageId`, `receipt` |
| `firestoreId` | `String?` | Yes | Deprecated Firestore key | `firestoreId` |
| `rawText` | `String?` | Yes | Raw OCR output | `rawText` |

---

### 2. ReceiptItem
Represents an itemized line inside a receipt. Currently defaulted to empty list under `Receipt`.

| Field Name | Data Type | Nullable | Description | Serialization Keys |
| :--- | :--- | :--- | :--- | :--- |
| `name` | `String` | No | Product title | `name` |
| `price` | `double` | No | Individual cost | `price` |
| `category` | `Category` | No | Item classification | `category` |

---

### 3. GalleryImage
Represents a scanned base64 image saved to MongoDB.

| Field Name | Data Type | Nullable | Description | Serialization Keys |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `String` | No | Unique MongoDB ID | `_id`, `id` |
| `base64` | `String` | No | Base64-encoded image content or hosted URL | `base64`, `imageUrl` |
| `timestamp` | `int` | No | Creation timestamp | `timestamp`, `createdAt` |
| `isProcessed` | `bool` | No | Processing status flag | `isProcessed` |
| `linkedReceiptId` | `String?` | Yes | Associated receipt reference ID | `linkedReceiptId`, `receipt` |

---

### 4. Category (Enum)
Supported categorization buckets:
*   `Food`
*   `Furniture`
*   `Stationery`
*   `Medicine`
*   `BabyAccessories`
*   `MobileAccessories`
*   `PetItems`
*   `BankPayment`
*   `Transport`
*   `Other`

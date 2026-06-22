# Product Requirements Document (PRD) — SmartScanner Pro

This document specifies the target requirements, core features, and architectural boundaries for the SmartScanner Pro mobile application.

---

## 1. Product Summary

SmartScanner Pro is a mobile utility designed to simplify expense tracking and budgeting. Users can photograph receipts using their mobile devices or import images from the local photo library. The app extracts text, calculates spending progress against a monthly budget, and aggregates expense categories automatically.

---

## 2. In-Scope Features (Active & Verified)

### 2.1 User Accounts & Secure Authentication
*   **User Registration:** Users must register with a username, email address, phone number, and a secure password.
*   **User Login:** Users log in using their email and password.
*   **Session Management:** Successful authorization returns a JWT token stored in SharedPreferences. Subsequent API requests carry the authorization token in headers.
*   **Auto Silent Auth:** If no token is detected on launch, the client app runs a background silent sign-up or login script using a default credential set to ensure uninterrupted user testing.

### 2.2 Receipt Scanning & Image Processing
*   **Dynamic Resolution Limits:** Captured images are dynamically resized down to a maximum width of 800px and compressed to 75% JPEG quality to optimize upload times.
*   **Base64 Transfer:** Compressed images are converted to base64 strings with standard image metadata headers.
*   **Server-Side AI OCR Analysis:** Scanned base64 images are sent to the REST endpoint `/receipts/analyze`. The backend server delegates the OCR extraction to the Gemini API, inserts the record to MongoDB, and returns the structured expense.

### 2.3 Local Image Vault
*   **Local Image Database:** Scanned images are displayed in the Vault grid.
*   **Base64 Memory Decoding:** Memory arrays are decoded dynamically from base64 strings and rendered as fit-to-frame preview tiles.
*   **Image Deletions:** Users can delete images, which removes them from both local view states and backend storage.

### 2.4 Expense Visualization & Analytics
*   **Total Spent Summary:** The app displays the month's spending vs the budget, with a colored progress bar that turns red when the budget is exceeded.
*   **Daily Spending Trends:** Displays a bar chart of spending over the last 7 days.
*   **Category breakdown:** Displays a pie chart of expenses categorized into: Food, Furniture, Stationery, Medicine, BabyAccessories, MobileAccessories, PetItems, BankPayment, Transport, and Other.

### 2.5 Budget Configurations
*   **Dynamic Setting Dialog:** Users can configure their monthly spending limit via a modal budget settings card. Budget values are sent to `/budget/:month` on the backend and persist across app sessions.

---

## 3. Out-of-Scope Features

*   **Local OCR Pipeline:** Direct client-side text recognition and entity extraction using Google ML Kit. Bypassed in favor of the server-side Gemini pipeline.
*   **Local Database Fallbacks:** Storing, fetching, or recovering receipt list objects locally on the device while offline.
*   **Social Interactions:** Liking, sharing, or commenting on user feed posts, even though endpoint mappings are declared in `ApiService`.

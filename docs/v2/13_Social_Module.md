# Social Module

The Social Module details the social features defined in the code.

## Available API Mappings

The following endpoints are mapped inside [ApiService](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/services/api_service.dart#L255):

*   **Share Receipt (`shareReceipt`):** POST request to `/social/share`. Shares a receipt with custom descriptions and visibility limits.
*   **Get Social Feed (`getSocialFeed`):** GET request to `/social/feed`. Fetches shared posts from followed users.
*   **Like Shared Post (`likeShare`):** POST request to `/social/:shareId/like`. Likes a shared receipt.
*   **Comment (`commentOnShare`):** POST request to `/social/:shareId/comment` with comment text in payload.
*   **Follow User (`followUser`):** POST request to `/social/users/:userId/follow`.
*   **Get Profile (`getUserProfile`):** GET request to `/social/users/:userId` to fetch user profiles.

## Current Integration Status
These API endpoints are defined in `ApiService` but are **not integrated or displayed** in the UI. They are reserved for future development phases.

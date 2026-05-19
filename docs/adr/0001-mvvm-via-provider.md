# ADR 0001: MVVM with Provider

- Status: Accepted
- Date: 2026-05-13

## Context
The app needs clear separation between UI rendering and receipt-processing logic while keeping implementation simple for Flutter developers.

## Decision
Use MVVM with Provider:
- View: widgets in [lib/main.dart](lib/main.dart) and [lib/components](lib/components)
- ViewModel: [lib/view_models/app_state.dart](lib/view_models/app_state.dart)
- Services: [lib/services](lib/services)

## Consequences
- Positive:
  - Predictable data flow.
  - Easier testing for service and state logic.
  - Lower coupling between UI and integrations.
- Negative:
  - AppState can become too large if not split by feature.

## Follow-up
When AppState grows, split into feature-specific view models and keep shared state minimal.

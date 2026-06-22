# ADR 0002: Service Layer Boundary Enforcement

- Status: Accepted
- Date: 2026-05-13

## Context
Receipt features use OCR, entity extraction, local storage, and Firestore. Without boundaries, these details leak into UI and state code.

## Decision
All business logic and integrations live in services.
- Processing: [lib/services/receipt_processing_service.dart](lib/services/receipt_processing_service.dart)
- Repository orchestration: [lib/services/receipt_repository.dart](lib/services/receipt_repository.dart)
- Local persistence: [lib/services/storage_service.dart](lib/services/storage_service.dart)

UI and ViewModel are forbidden from direct database or API access.

## Consequences
- Positive:
  - Integrations are isolated.
  - Future API swaps are easier.
  - Better testability.
- Negative:
  - More files and indirection.

## Follow-up
Enforce during PR review: reject UI/ViewModel imports of persistence or API packages.

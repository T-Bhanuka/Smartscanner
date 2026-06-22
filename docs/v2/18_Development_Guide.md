# Development Guide

This guide outlines directory structures, coding styles, and contribution requirements for the project.

## 1. Directory Structure

Ensure new files align with our directory mapping:
*   `/lib/screens/` — Add new screen layouts.
*   `/lib/components/` — Add reusable child widgets (e.g. charts, lists).
*   `/lib/services/` — Add backend services or integrations.
*   `/lib/types.dart` — All serializable data models must reside here.

## 2. Naming & Style Conventions

*   **Files:** Use lowercase snake_case naming conventions (e.g., `receipt_card.dart`).
*   **Classes:** Use PascalCase naming conventions (e.g., `ReceiptCard`).
*   **Variable Names:** Use camelCase naming conventions (e.g., `totalSpent`).
*   **Code Formatting:** Run the formatter before committing:
    ```bash
    dart format .
    ```
*   **Linting Rules:** All code must conform to the rules in [analysis_options.yaml](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/analysis_options.yaml).

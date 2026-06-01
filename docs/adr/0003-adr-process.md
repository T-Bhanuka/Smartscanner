# ADR 0003: ADR Process for Architecture Changes

- Status: Accepted
- Date: 2026-05-13

## Context
Architecture decisions were not previously captured, making later changes harder to reason about.

## Decision
Adopt a lightweight ADR process in [docs/adr](docs/adr).

Each ADR must include:
- Context
- Decision
- Consequences
- Follow-up actions

Naming convention:
- `NNNN-short-kebab-title.md` (example: `0004-state-split-by-feature.md`)

## Consequences
- Positive:
  - Preserves why decisions were made.
  - Helps onboarding and AI-assisted changes.
- Negative:
  - Small documentation overhead.

## Follow-up
Create a new ADR whenever architecture direction, layering, persistence strategy, or state pattern changes.

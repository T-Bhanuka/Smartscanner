# Critical Errors and Bottlenecks

## 1. Broken data flow (highest risk)

- **Issue:** [lib/main.dart](lib/main.dart) writes scanned receipts to Firestore in `_processReceipt()`, but UI reads receipts from local `StorageService`.
- **Result:** Newly scanned receipts may not appear in Dashboard/Archive, causing silent data inconsistency.

## 2. Unused/abandoned AI path

- **Issue:** [lib/services/gemini_service.dart](lib/services/gemini_service.dart) is implemented but not integrated into the main flow.
- **Result:** Team may think Gemini logic is active, but runtime uses ML Kit path only.

## 3. Gallery feature is structurally incomplete

- **Issue:** `GalleryImage` model and `saveGalleryImage()` exist, but scan/gallery flow does not persist image records consistently.
- **Result:** Vault tab risks being empty/inaccurate relative to user actions.

## 4. OCR pipeline quality limitations

- **Issue:** `TextRecognizer` is locked to Latin script while documentation implies Sinhala/Tamil support.
- **Result:** Non-Latin receipts will fail or produce invalid OCR.

## 5. Entity extraction uses English model only

- **Issue:** Currency/date parsing and amount detection can be wrong or unstable for local receipts.
- **Impact:** Performance bottleneck in UI compute path — Dashboard recomputes per-day and per-category aggregations in widget build.

## 6. Security/configuration anti-patterns

- **Issue:** Gemini API key placeholder in source file encourages hardcoding secrets.
- **Issue:** Firebase options are committed; environment handling is not clearly separated for dev/stage/prod.

## 7. State management/architecture bottleneck

- **Issue:** [lib/main.dart](lib/main.dart) is a large monolith handling UI, scanning, persistence, and orchestration.
- **Result:** Hard to test, reason about, and evolve without regressions.

## 8. Test suite is invalid for current app

- **Issue:** [test/widget_test.dart](test/widget_test.dart) is default counter test and does not represent app behavior.
- **Result:** Gives false confidence and misses critical regressions.

## 9. Error handling and observability gaps

- **Issue:** Generic `catch(e)` and user-facing text only; no structured logging, no telemetry, limited actionable diagnostics.

## 10. Product/docs mismatch

- **Issue:** README and naming still indicate template project (first_project), not SmartScanner behavior.
- **Result:** Onboarding and maintenance cost increases.

---

## Resolution Plan (VS Code Implementable)

### Phase 1 — Stabilize Correctness First

- Define a single source of truth for receipt persistence (local-first or Firestore-first) and align read/write paths.
- Wire scan results into that unified repository flow so Dashboard/Archive/Vault all update from the same model.
- Remove dead paths or explicitly feature-flag unfinished flows (Gemini, hybrid storage).

### Phase 2 — Refactor Architecture for Maintainability

- Split main.dart responsibilities into layers: presentation, use-cases/services, repositories, models.
- Introduce explicit state management boundaries for scanner state, receipt state, and settings state.
- Move OCR/AI parsing logic into dedicated services with typed result contracts.

### Phase 3 — Improve OCR and Parsing Reliability

- Add a normalization/validation pipeline for extracted text (amount/date/category confidence checks).
- Handle multilingual receipts explicitly (script/language strategy, fallbacks, confidence thresholds).
- Add deterministic fallback rules when OCR entities are weak.

### Phase 4 — Security and Configuration Hardening

- Move keys/secrets to secure runtime config (no source hardcoding).
- Separate Firebase/project configuration per environment.
- Add input/output validation around external AI responses.

### Phase 5 — Performance Optimization

- Precompute or cache dashboard aggregates outside widget build.
- Avoid repeated DateTime.parse and full-list scans on every rebuild.
- Add lightweight profiling checkpoints for scan-to-render latency.

### Phase 6 — Testing and Quality Gates

- Replace template test with real widget/unit tests for scan flow, parsing logic, storage sync, and budget/dashboard behavior.
- Add integration tests for critical user journeys (capture → parse → persist → display).
- Enable CI checks for analyze/test and fail on regressions.

### Phase 7 — Documentation and Developer Hygiene

- Update README to actual architecture, run steps, data flow, and known limitations.
- Add contribution notes: folder conventions, coding standards, and testing expectations.
- Rename project/package identifiers from template names to consistent product naming.
## Suggested Execution Order in VS Code

1. Data-flow unification + correctness fixes
2. Architecture split of [lib/main.dart](lib/main.dart)
3. Test replacement and CI baseline
4. OCR reliability improvements
5. Security/config cleanup
6. Performance pass + documentation

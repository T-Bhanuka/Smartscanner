Critical errors and bottlenecks I see:

Broken data flow (highest risk)
/home/runner/work/Smartscanner/Smartscanner/lib/main.dart writes scanned receipts to Firestore in _processReceipt, but UI reads receipts from local StorageService.
Result: newly scanned receipts may not appear in Dashboard/Archive, causing silent data inconsistency.
Unused/abandoned AI path
/home/runner/work/Smartscanner/Smartscanner/lib/services/gemini_service.dart is implemented but not integrated.
Team may think Gemini logic is active, but runtime uses ML Kit path only.
Gallery feature is structurally incomplete
GalleryImage model and saveGalleryImage exist, but scan/gallery flow does not persist image records consistently.
Vault tab therefore risks being empty/inaccurate relative to user actions.
OCR pipeline quality limitations
TextRecognizer is locked to Latin script while prompt/comments imply Sinhala/Tamil support.
Entity extraction uses English model only; currency/date parsing and amount detection can be wrong or unstable for local receipts.
Performance bottleneck in UI compute path
Dashboard recomputes per-day and per-category aggregations in widget build.
As receipt count grows, repeated parsing/filtering in build can degrade rendering responsiveness.
Security/configuration anti-patterns
Gemini API key placeholder in source file encourages hardcoding secrets.
Firebase options are committed and environment handling is not clearly separated for dev/stage/prod.
State management/architecture bottleneck
main.dart is a large monolith handling UI, scanning, persistence, and orchestration.
Hard to test, reason about, and evolve without regressions.
Test suite is invalid for current app
/home/runner/work/Smartscanner/Smartscanner/test/widget_test.dart is default counter test and does not represent app behavior.
Gives false confidence and misses critical regressions.
Error handling and observability gaps
Generic catch (e) and user-facing text only; no structured logging, no telemetry, limited actionable diagnostics.
Product/docs mismatch
README and naming still indicate template project (first_project), not Smartscanner behavior.
Onboarding and maintenance cost increases.
Resolution plan (VS Code implementable):

Phase 1 — Stabilize correctness first

Define a single source of truth for receipt persistence (local-first or Firestore-first) and align read/write paths.
Wire scan results into that unified repository flow so Dashboard/Archive/Vault all update from the same model.
Remove dead paths or explicitly feature-flag unfinished flows (Gemini, hybrid storage).
Phase 2 — Refactor architecture for maintainability

Split main.dart responsibilities into layers: presentation, use-cases/services, repositories, models.
Introduce explicit state management boundaries for scanner state, receipt state, and settings state.
Move OCR/AI parsing logic into dedicated services with typed result contracts.
Phase 3 — Improve OCR and parsing reliability

Add a normalization/validation pipeline for extracted text (amount/date/category confidence checks).
Handle multilingual receipts explicitly (script/language strategy, fallbacks, confidence thresholds).
Add deterministic fallback rules when OCR entities are weak.
Phase 4 — Security and configuration hardening

Move keys/secrets to secure runtime config (no source hardcoding).
Separate Firebase/project configuration per environment.
Add input/output validation around external AI responses.
Phase 5 — Performance optimization

Precompute or cache dashboard aggregates outside widget build.
Avoid repeated DateTime.parse and full-list scans on every rebuild.
Add lightweight profiling checkpoints for scan-to-render latency.
Phase 6 — Testing and quality gates

Replace template test with real widget/unit tests for scan flow, parsing logic, storage sync, and budget/dashboard behavior.
Add integration tests for critical user journeys (capture → parse → persist → display).
Enable CI checks for analyze/test and fail on regressions.
Phase 7 — Documentation and developer hygiene

Update README to actual architecture, run steps, data flow, and known limitations.
Add contribution notes: folder conventions, coding standards, and testing expectations.
Rename project/package identifiers from template names to consistent product naming.
Suggested execution order in VS Code:

Data-flow unification + correctness fixes
Architecture split of main.dart
Test replacement and CI baseline
OCR reliability improvements
Security/config cleanup
Performance pass + documentation


https://github.com/T-Bhanuka/Smartscanner/tasks/9751f9cb-5dc1-4267-8a23-42f5a86d3de6

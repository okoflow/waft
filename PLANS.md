# Plans

This page gives the ordered audit fixes and the checks for each step.
[AUDIT.md](AUDIT.md) records the risks and decisions;
[CONTRIBUTING.md](CONTRIBUTING.md) defines the checks and test conventions.

## Execution rules

Work on one step at a time. After each step, run the full `make check` and
resolve failures before starting the next step. Keep every change uncommitted.
Use fake dependencies and temporary files; do not invoke the live app,
microphone, keychain, Accessibility, bundle, or release workflow.

Use the existing localized keys for accessibility changes. Run
`make strings-update` for any changed user-facing string and verify all 23
tables. Preserve every stored key and setting name.

## Ordered steps

1. Remove response bodies from network failure logging (A01). Keep typed
   failure mapping and test hostile error payloads and failed responses.
   Remove obsolete parsing and redaction. Verify with `make check`.
2. Delete recovery copies on explicit storage deletion (A02). Test both
   files, absent primary, repeated deletion, and unchanged recovery on load.
   Update the privacy documentation. Verify with `make check`.
3. Revalidate speech-model selection after startup suspension (A03). Hold the
   initial installation query, change the selection, and prove only the
   current model is loaded. Verify with `make check`.
4. Stop canceled file and server-detection work at suspension boundaries
   (A06). Test cancel, reset, replacement, and failed superseded requests with
   held fakes. Verify with `make check`.
5. Break callback ownership cycles (A08). Prove an unstarted app graph and its
   dependent models release without touching system services. Verify with
   `make check`.
6. Resolve custom-mode bindings against current settings (A10). Test retained
   bindings, independent field edits, and deletion. Verify with `make check`.
7. Preserve API key drafts after failed saves (A11). Test failed initial and
   replacement saves, successful saves, and logging-helper success results.
   Verify with `make check`.
8. Report model-cache inspection errors conservatively (A12). Test absent
   cache, incomplete files, and an injected inspection failure. A regular
   file returns an empty listing on the current runtime and cannot stand in
   for a failing inspection. Verify with `make check`.
9. Revalidate delayed onboarding advancement (A13). Test revocation and
   superseded transitions using fake permissions. Verify with `make check`.
10. Add the instructions label and history content direction (A18, A19).
    Reuse existing translations, exercise direction/label behavior through
    available view tests, and run `make strings-update` and `make check`.
    If native view validation cannot be made reliable, record the limitation
    or skip the risky part explicitly in `AUDIT.md`.
11. Reconcile every audit status, review the entire diff and protected files,
    and run the final `make check`. Report native UI/hardware and Swift 6.3
    verification limits without claiming those checks ran.

## Progress

| Step | State | Verification |
| --- | --- | --- |
| Baseline | Native-service failures. | Source checks and build passed. Five existing pasteboard/media issues remain. Periphery and all 23 language tables passed separately. |
| 1 | Implemented; native gate blocked. | All seven new cases pass. Full `make check` reports only the same five baseline native-service issues. Periphery and strings pass separately. |
| 2–10 | Pending the check-gate exception. | No edits; baseline native failures prevent a green `make check`. |
| 11 | Current diff reviewed; full plan incomplete. | Protected files unchanged; `git diff --check` passes. Final green `make check` remains blocked. |

Standalone AppKit and AVFoundation probes reproduce the native failures
without importing Waft. The pasteboard rejects a synthetic write, and media
conversion fails after confirming a complete, readable fixture. See
[AUDIT.md](AUDIT.md) for diagnostics. The gate exception remains unanswered;
no subsequent implementation step has begun.

# Audit

This page records the code audit, ranked findings, and their disposition.
[PLANS.md](PLANS.md) gives the implementation and verification sequence;
[Architecture](docs/architecture.md) defines the rules used for this review.

## Scope and baseline

The review covered all five modules, their tests, package settings, CI, and
the privacy and localization contracts before source edits began. Locations
below identify the original tree; symbols remain useful after lines move.
The initial working tree was clean.

The installed compiler is Swift 6.4. The package retains Swift 6.3 tools and
language compatibility, strict checking, and warnings as errors. No package,
version, signing, entitlement, update key, or persisted setting changes are
planned. Native app, microphone, Accessibility, keychain, and network tests
are outside the automated test run.

## Findings ranked by impact

| ID | Impact and location | Risk and proposed fix | Status |
| --- | --- | --- | --- |
| A01 | High: `Sources/WaftPlatform/Network/HTTPRewriter.swift:63`, `OpenAIAPI.swift:57`, `APIErrorBody.swift:9` | Arbitrary API message, type, and code strings reach logs; a server can echo text or keys. Log only fixed service names, HTTP status, and fixed failure messages; remove unused error-body redaction. | Fixed: Logs no longer consume server diagnostics; obsolete parsing is removed. Seven regression cases pass. Malformed optional OpenAI diagnostics no longer override the failed response's service error. |
| A02 | High: `Sources/WaftPlatform/Storage/JSONFileStore.swift:48`, `Sources/WaftFeatures/Models/HistoryModel.swift:93` | **Clear History** leaves `history.unreadable.json` behind. Explicit deletion must remove the primary and recovery copy independently, including when the primary is absent. | Left for the owner pending the check-gate exception. |
| A03 | High: `Sources/WaftFeatures/Models/SpeechModelController.swift:36` | A selection change during startup's installation query can load the old model and delete the selected one. Revalidate the selection after suspension and repeat the query when it changes. | Left for the owner pending the check-gate exception. |
| A04 | High: `Sources/WaftPlatform/Accessibility/AccessibilityElement.swift:68` | Different fields with the same role and window compare as the same focus, risking insertion into the wrong field. Strengthen identity only after testing applications that recreate accessibility elements. | Skipped: Changing this compatibility fallback needs a browser, Electron, and native-app focus matrix that cannot be exercised by fake-only tests. |
| A05 | Medium: `Sources/WaftPlatform/Storage/JSONFileStore.swift:39`, `:54` | Fresh private content is written before permissions become `0600`; failures can leave default permissions. A synthetic probe observes `0644` before chmod with umask `022`; replacement of an existing `0600` file retains that mode. Create a restricted temporary file before writing and atomically replace the destination. | Left for the owner: A secure writer needs separate failure-injection and filesystem testing; cross-user exposure also depends on ancestor permissions and ACLs. |
| A06 | Medium: `Sources/WaftFeatures/Transcription/FileTranscriptionModel.swift:103`, `Sources/WaftFeatures/Models/LocalModelsModel.swift:62` | Canceled decoding still starts recognition, and canceled server detection continues probing. Check cancellation before expensive work and after suspension, and test superseded work with held fakes. | Left for the owner pending the check-gate exception. |
| A07 | Medium: `Sources/WaftSpeech/WhisperTranscriber.swift:73`, `:115`, `:228` | Queued recognition retains audio while waiting and can start language detection after cancellation. Introduce a cancellation-aware turn coordinator and check cancellation after admission. | Skipped: Replacing WhisperKit serialization needs dedicated queue tests and recognition integration validation; the model-level cancellation fix does not claim to solve already queued adapter work. |
| A08 | Medium: `Sources/WaftFeatures/App/AppModel.swift:140` | Settings and Pro callbacks strongly capture models that retain those objects. Use weak captures and test release of an unstarted app graph. | Left for the owner pending the check-gate exception. |
| A09 | Medium: `Sources/WaftPlatform/Keyboard/KeyEventTap.swift:82`, `CarbonHotKey.swift:30`, `Sources/WaftPlatform/System/WorkspaceAppMonitor.swift:39` | Unretained callback contexts and notification registrations lack teardown. Add lifetime-owned registrations and isolated cleanup. | Left for the owner: These are currently app-lifetime adapters. Safe teardown needs registration seams and native callback tests before shortening their lifetime. |
| A10 | Medium: `Sources/WaftFeatures/Settings/Writing/ModeEditorPage.swift:63` | Bindings capture a whole custom-mode snapshot; editing one field can restore stale values in another. Resolve the current record by ID for every read and write. | Left for the owner pending the check-gate exception. |
| A11 | Medium: `Sources/WaftFeatures/Models/APIKeyModel.swift:28` | A failed key save discards the replacement draft. Return success from the logging helper and clear the draft only after a successful save. | Left for the owner pending the check-gate exception; additional visible failure presentation also needs a product decision and translations. |
| A12 | Medium: `Sources/WaftSpeech/SpeechModelFiles.swift:39` | `try?` treats unreadable download metadata as a complete installation. Distinguish missing metadata from inspection failures, log only error metadata, and fail conservatively. A regular-file cache returns an empty listing here, so error-path tests need an injected failure instead. | Left for the owner pending the check-gate exception. |
| A13 | Medium: `Sources/WaftFeatures/Onboarding/OnboardingModel.swift:95` | A permission revoked during the success pause still advances onboarding. Recheck the permission after the pause and invalidate superseded transitions. | Left for the owner pending the check-gate exception. |
| A14 | Medium: `Sources/WaftFeatures/Settings/AIModels/LocalServerSection.swift:25`, `ModeEditorPage.swift:23`, `Sources/WaftPlatform/Network/LocalServer+URL.swift:13` | UI promises processing stays on this Mac, but configured remote hosts are supported. Either describe remote processing truthfully in all languages or define a loopback-only migration. | Skipped: Endpoint support and wording require a product decision; existing endpoints must keep working. |
| A15 | Medium: `Sources/WaftFeatures/Models/HistoryModel.swift:107` | Retention is enforced only at startup, insertion, or changed limits. An idle process can retain expired history. Define periodic and wake-time cleanup. | Left for the owner: Deletion cadence and sleep/wake behavior need an explicit retention policy. |
| A16 | Medium: `Sources/WaftPlatform/Audio/AudioSampleSink.swift:69`, `:88` | The callback allocates conversion buffers and grows storage under a lock. Profile long recordings and representative input formats before changing buffer ownership. | Skipped: No measured glitch; audio-thread changes need hardware profiling and would otherwise be speculative. |
| A17 | Medium: `Sources/WaftPlatform/Media/MediaAudioReader.swift:72`, `Sources/WaftSpeech/WhisperTranscriber.swift:103` | File transcription materializes full audio and copied chunks. Stream with an explicit memory budget for multi-hour input. | Skipped: This changes interfaces, progress, and cancellation; it needs large-file benchmarks and a separate design. |
| A18 | Low: `Sources/WaftFeatures/DesignSystem/InputEditor.swift:12` | The instructions editor has no explicit accessibility label. Require a localized label and reuse the existing “Instructions” key. | Skipped: An offscreen host exposes no accessibility tree in this environment, and the underlying text view does not reflect SwiftUI's label. Actual accessibility-tree and VoiceOver validation is needed for a meaningful regression. |
| A19 | Low: `Sources/WaftFeatures/Settings/History/HistorySettingsPane.swift:112` | History text does not use its own script direction, unlike other transcript views. Apply the shared direction modifier to transcript content. | Left for the owner pending the check-gate exception; live mixed-direction rendering also needs verification. |
| A20 | Low: `Sources/WaftFeatures/Settings/AIModels/LocalServerSection.swift:27`, `Sources/WaftFeatures/Models/LocalModelsModel.swift:49` | Status and model choices can describe an address that has since been edited. Invalidate stale state and reject responses for obsolete addresses. | Left for the owner: Decide whether address edits immediately clear choices or wait for submit; do not introduce network requests on every keystroke. |
| A21 | Low: `Sources/WaftPlatform/Network/LocalServer+URL.swift:5` | String concatenation accepts relative/non-HTTP URLs and mishandles query or fragment components. Validate components and append endpoint paths structurally. | Skipped: Existing query/authentication parameters need a compatibility policy before normalizing stored endpoints. |

## Architecture and coverage observations

- Module dependencies point toward `WaftCore`; feature models receive core
  interfaces. Foundation-only core logic and main-actor UI isolation remain
  appropriate. No broad architecture rewrite is justified.
- The audio recorder and transcriber already use actors. Shared sample and
  meter state uses locks; unchecked sendability at system callback boundaries
  requires the lifetime and hardware follow-ups above.
- Typed rewrite errors, lenient per-field settings decoding, and explicit
  storage logging are established conventions. Missing cancellation, stale
  snapshots, and failed-save tests are addressed by the planned regressions.
- Network sessions already use ephemeral configurations, OpenAI requests
  disable storage, and WhisperKit logging is disabled. Password-field text
  staying available for explicit copy is intentional and already tested.
- Leading/trailing layout, directional symbols, localized domain names, and
  the 23-language table check are established. The editor and history gaps
  above are localized exceptions. Translation quality is not a native-speaker
  review, and live accessibility is not covered by unit tests.
- Existing helpers avoid substantial cross-module duplication. Dead code is
  checked by Periphery; obsolete error parsing will be removed with A01.
  No new dependency is warranted.

## Verification record

The ordinary baseline `make check` reached build after passing source checks,
then failed because compiler caches were outside the writable sandbox.
Verification uses temporary tool wrappers under `/tmp/waft-audit-tools` to
place caches in `/tmp`, disable SwiftLint's unwritable cache, and disable
SwiftPM's nested process sandbox. The enclosing workspace sandbox remains
active. No repository check or compiler warning rule is weakened.

With those wrappers, the baseline build passed. The tests reported five
issues in existing native-service checks: both media-reader channel cases,
private pasteboard writing, and two pasteboard snapshot cases. Under the
sandbox, pasteboard writes fail and the media reader reports unreadable
audio. Core, feature, speech, and remaining platform tests passed. Periphery
and the strings check passed separately: 407 keys across 23 languages.

The current run and each implementation step are recorded in
[PLANS.md](PLANS.md). An exception to the green-check gate was requested
because these baseline native failures cannot be fixed by changing the
audited code. No later implementation step starts without that exception.
Swift 6.3 and native UI/hardware checks remain owner/CI verification. The
local toolchain also emits existing linker search-path warnings for missing
Command Line Tools directories; no source warning rule has been relaxed.

After A01, `make check` again passed formatting, SwiftLint, ShellCheck,
spelling, gitleaks, and build. Its tests passed the new diagnostic cases and
reported exactly the same five baseline native-service issues. Periphery
passed separately with no unused code, and strings still passed with 407
keys in 23 languages. `git diff --check` passed. Protected configuration,
package dependencies, and packaging files have no changes.

You can inspect the local execution logs in
`/tmp/waft-baseline-check.log`, `/tmp/waft-step1-check.log`, and
`/tmp/waft-step1-periphery.log`. A complete passing `make check` remains
outstanding; this audit does not claim completion of the refactoring plan.

An independent AppKit probe using a uniquely named temporary pasteboard,
without importing Waft, also rejects its synthetic write: the change count
stays zero, types are absent, and the probe cannot read its own fixture.
This reproduces the pasteboard blocker outside the application's adapters;
changing those adapters would not repair the unavailable test service.
The diagnostic output is in `/tmp/waft-pasteboard-probe.log`.

A separate media probe explicitly closes its synthetic WAV writer and
confirms all 44,100 frames can be read. `AVAssetReader` passes through the
original mono and stereo audio, but conversion to floating-point PCM fails
before reading, even at the original rate and channel count. The error is
`AVFoundationErrorDomain -11800`, with underlying `NSOSStatusErrorDomain -1`.
This rules out an unflushed fixture; it does not distinguish a sandbox
restriction from a host conversion-backend failure. The output is in
`/tmp/waft-media-probe.log`. Neither probe uses Waft's adapters.

The storage probe in `/tmp/waft-storage-probe-results.txt` confirms A05's
fresh-file permission gap and corrects A12's proposed error fixture. A missing
cache reports Cocoa error `260` with POSIX error `2`, while a regular-file
cache returns an empty list. The later keyboard and usage-document edits
were present when this goal resumed and have been preserved; they were not
part of the initial audit or the A01 implementation.

## External references

Repository rules take precedence over general guidance. The concurrency
review also checked Swift's
[default nonisolated execution guidance](https://docs.swift.org/latest/documentation/diagnostics/nonisolated-nonsending-by-default/).
The network review checked Apple's
[ephemeral session contract](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/ephemeral).

# Waft

On-device dictation for macOS with AI cleanup. A global key starts and stops the recording, Whisper recognizes the speech on the Mac through WhisperKit, a mode cleans the text up offline or with Claude, OpenAI, or a local server, and the result is pasted into the focused field through the clipboard.

The Swift package has five modules: `WaftCore` (domain and every interface between modules, Foundation only), `WaftSpeech` (WhisperKit), `WaftPlatform` (macOS adapters, AI APIs, Sparkle), `WaftFeatures` (main-actor models and SwiftUI), and `Waft` (the app and composition root). [Architecture](docs/architecture.md) maps the code, and [CONTRIBUTING.md](CONTRIBUTING.md) holds every rule: read the sections linked below before you change code or docs, or commit.

## Commands

- `make check` runs every check but `bundle`. Run it before you push.
- `make test` runs the tests. A plain `swift test` can miss the Swift Testing plugins.
- `make format` fixes what `make format-check` reports.
- `make strings-update` rewrites the English strings table from the code.
- Run `make bundle` or `make run` only when asked. Both re-sign `build/Waft.app`, the copy the maintainer runs, and without the Waft Dev identity they sign it ad hoc, which resets its permissions.

## Rules that are easy to miss

- No comments in code ([Naming and files](CONTRIBUTING.md#naming-and-files)), and no `&&`, `||`, `??`, or `try?` that hides a failure ([Control flow](CONTRIBUTING.md#control-flow)).
- Blank lines separate the steps of a function and every block or closure of several lines, which no formatter adds for you: [Layout](CONTRIBUTING.md#layout).
- No `@State`, `@Entry`, `@Animatable`, or `#Preview`, and `package import` only where a signature needs it: [Platform](CONTRIBUTING.md#platform).
- Every user-facing string goes into every table under `Packaging/Localizations`, and Swift file names stay unique across `Sources`, since `make strings` finds strings by file name: [Text and translations](CONTRIBUTING.md#text-and-translations).
- Never log dictated text, audio, or clipboard contents, and keep dependencies pointing toward `WaftCore`, with concrete adapters named only in `AppDependencies.live()`: [Invariants](docs/architecture.md#invariants).
- A test file follows the pattern in [Tests](CONTRIBUTING.md#tests), and a script the layout in [Shell scripts](CONTRIBUTING.md#shell-scripts).
- Docs follow [Documentation](CONTRIBUTING.md#documentation) and change in the same pull request as the behavior they describe.
- Commits and pull requests follow [Commits](CONTRIBUTING.md#commits) and [Pull requests](CONTRIBUTING.md#pull-requests): no trailers such as `Co-authored-by:`, and a pull request body that lists the checks you ran after `Verified:`.

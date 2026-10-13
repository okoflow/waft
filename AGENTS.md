# Waft

On-device dictation for macOS with AI cleanup. Holding a key records the
microphone, Whisper recognizes the speech on the Mac through WhisperKit, a
mode cleans the text up offline or with Claude, OpenAI, or a local server, and
the result is pasted into the focused field through the clipboard.

The Swift package splits into `WaftCore` (domain and every interface,
Foundation only), `WaftSpeech` (WhisperKit), `WaftPlatform` (macOS adapters,
AI APIs, Sparkle), `WaftFeatures` (main-actor models and SwiftUI), and `Waft`
(the app and composition root). [Architecture](docs/architecture.md) has the
code map, and [CONTRIBUTING.md](CONTRIBUTING.md) the rules and checks.

## Commands

- `make check` runs every check and must pass before a commit. CI runs it and
  then `make bundle`.
- `make test` runs the tests. It passes `swift test` the paths of Swift
  Testing and its macro plugins, which a plain `swift test` can miss with the
  Command Line Tools alone.
- `make format` fixes what `make format-check` reports.
- `make strings-update` rewrites the English strings table from the code.
- Run `make bundle` or `make run` only when asked. Both re-sign
  `build/Waft.app`, the copy the maintainer runs, and without the Waft Dev
  identity they sign it ad hoc, which resets its permissions.

## Rules that are easy to miss

- The package builds with the Command Line Tools alone: no `@State`,
  `@Entry`, `@Animatable`, or `#Preview`.
- CI runs every check with the Command Line Tools for Xcode 27 and Swift 6.4,
  and builds and tests with the Command Line Tools for Xcode 26 too. Warnings
  are errors in both.
- No comments in code, no `??`, and no `try?` that hides a failure. Return
  early with `guard`, throw typed errors for closed failure sets, and log the
  rest.
- `InternalImportsByDefault` is on: an import is `package import` only when a
  package declaration's signature uses its types.
- Every user-facing string needs an entry in every table under
  `Packaging/Localizations`; `make strings` fails otherwise. It finds each
  Swift file's extracted strings by the file name, so keep the names of Swift
  files in `Sources` unique across modules.
- Never log dictated text, audio, or clipboard contents.
- Commits follow Conventional Commits with a scope from the list in
  [CONTRIBUTING.md](CONTRIBUTING.md#commits) or none, and carry no trailers
  such as `Co-authored-by:`.
- A pull request's title and body become the merge commit's subject and body.
  Write the title in commit form and the body as a commit body that ends with
  `Verified:` and the checks you ran.

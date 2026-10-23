# Waft

On-device dictation for macOS with AI cleanup. A global key starts and stops
the recording, Whisper recognizes the speech on the Mac through WhisperKit, a
mode cleans the text up offline or with Claude, OpenAI, or a local server, and
the result is pasted into the focused field through the clipboard.

The Swift package splits into `WaftCore` (domain and every interface between
modules, Foundation only), `WaftSpeech` (WhisperKit), `WaftPlatform` (macOS
adapters, AI APIs, Sparkle), `WaftFeatures` (main-actor models and SwiftUI),
and `Waft` (the app and composition root).
[Architecture](docs/architecture.md) has the code map, and
[CONTRIBUTING.md](CONTRIBUTING.md) the rules and checks.

## Commands

- `make check` runs every check but `bundle`; run it before you push.
- `make test` runs the tests; [Tests](CONTRIBUTING.md#tests) says why not a
  plain `swift test`.
- `make format` fixes what `make format-check` reports.
- `make strings-update` rewrites the English strings table from the code.
- Run `make bundle` or `make run` only when asked. Both re-sign
  `build/Waft.app`, the copy the maintainer runs, and without the Waft Dev
  identity they sign it ad hoc, which resets its permissions.

## Rules that are easy to miss

- The package builds with the Command Line Tools alone: no `@State`,
  `@Entry`, `@Animatable`, or `#Preview`.
- CI runs `make check` and `make bundle` with the Command Line Tools for
  Xcode 27 and Swift 6.4, and builds and tests with the Command Line Tools for
  Xcode 26 too. Warnings are errors in both.
- No comments in code, no `??`, and no `try?` that hides a failure. Return
  early with `guard`, throw typed errors for a closed set of failures that
  every caller handles, and throw or log the rest.
- `InternalImportsByDefault` is on: an import is `package import` only when a
  package declaration's signature names its types. A type reached through an
  alias, such as `CustomMode.ID` for `UUID`, doesn't count, and Swift 6.3
  rejects the unused `package import`.
- Every user-facing string needs an entry in every table under
  `Packaging/Localizations`; `make strings` fails otherwise. It finds each
  Swift file's extracted strings by the file name, so keep the names of Swift
  files in `Sources` unique across modules.
- Never log dictated text, audio, or clipboard contents.
- Docs follow the pattern in [Documentation](CONTRIBUTING.md#documentation)
  and change in the same pull request as the behavior they describe.
- Commits follow Conventional Commits with a scope from
  [Commits](CONTRIBUTING.md#commits) or none, and carry no trailers such as
  `Co-authored-by:`.
- A pull request's title and body become the merge commit's subject and body.
  Write the title in commit form and the body as a commit body that ends with
  `Verified:` and the checks you ran, then `Fixes #N` when it closes an issue.

# Contributing

This page covers the setup, the checks, and the rules for code, tests, scripts, docs, commits, and pull requests. [Architecture](docs/architecture.md) maps the code, and [Releasing](docs/releasing.md) covers releases. Everyone who takes part follows [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Ways to contribute

- **Report a bug or propose a feature** with the issue forms.
- **Report a vulnerability** privately, as [SECURITY.md](SECURITY.md) describes.
- **Send a pull request** for an open issue. For anything larger than a fix, agree on the approach in the issue first.

## Development setup

You need a Mac with Apple silicon, macOS 26.6 or later, and the Command Line Tools for Xcode 27, which `xcode-select --install` installs.

```sh
git clone https://github.com/okoflow/waft.git
cd waft
make signing
make run
```

- `make signing` creates the Waft Dev code-signing identity in your login keychain once and asks for your password to trust it. Without it, every build is signed ad hoc and macOS forgets the permissions you granted: rebuild, remove the old Waft entries under Microphone and Accessibility in System Settings › Privacy & Security, and allow them again.
- `make run` builds the debug configuration, signs it, and opens `build/Waft.app`; add `CONFIG=release` for an optimized build. A debug build doesn't update itself.
- `make help` lists every target.

To change the code, install the tools in the [Brewfile](Brewfile) with [Homebrew](https://brew.sh), and the pre-commit hook:

```sh
brew bundle
make hooks
```

## Checks

Run `make check` before you push. It runs `format-check`, which `make format` fixes, `lint`, `shellcheck`, `spelling`, `secrets`, `build` with warnings as errors, `test`, `periphery` for unused code, and `strings` for the translations. It leaves out `bundle`, which re-signs the app you run. CI runs `make check` and `make bundle` on every pull request and push to `main` with the Command Line Tools for Xcode 27, launches the bundled app on macOS 15, the oldest system GitHub hosts, and runs `make test` with the tools for Xcode 26.

Fix the code rather than the rule. A rule that is wrong for one line gets a `// swiftlint:disable:next <rule>` or `// swiftformat:disable:next <rule>` directive.

## Code

SwiftFormat and SwiftLint settle formatting, the order of declarations, and the limits on size. The rules below are the ones no tool checks, or that you need before you write the code.

### Naming and files

- Name things after what they are and do, in full words, following the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/): `statisticsFile`, not `statsFile`.
- No comments in code: names, types, and small functions carry the meaning.
- One main type per file, named after it. An extension of another type goes into `<Type>+<Topic>.swift`, such as `String+Capitalization.swift`.
- Keep the names of Swift files unique across `Sources`: `make strings` finds each file's strings by its name.
- Give every declaration the narrowest access level that works.

### Control flow

- Keep the happy path at the left margin: check preconditions with `guard` at the top of a function and return or throw early.
- No `&&` or `||` in `Sources`. Separate conditions with commas, write an alternative as a `guard … else { return true }` followed by the second check or as `[first, second].contains(true)`, and give a long condition a name that reads as an assertion, such as `canSaveDraft`.
- No `??`. Unwrap with `guard let`, throw when absence is a failure, and use a dictionary's `default:` subscript for lookups.
- No `try?` that hides a failure: throw it or log it. `try?` is fine only in a `let` binding where absence is the result, as in `guard let key = try? PublicKey(…)`.
- A closed set of failures gets its own error enum, thrown with typed throws when every caller handles every case, as `RewriteError` is.
- A `switch` that lists every case on a line of its own follows the order of the enum's declaration.

### Layout

- Separate the steps of a function with one blank line: the guards, the values it prepares, the work, and the result. Statements of one kind stay together.
- A block of several lines, such as an `if`, a `switch`, a loop, a `do`/`catch`, or a closure, gets a blank line before and after it, unless it is first or last in its body.
- A `guard` stays directly under the single line that declares the value it checks. After any other statement of several lines, leave a blank line before the `guard`.

### Platform

- The package builds with the Command Line Tools alone, which lack Xcode's SwiftUI macro plugins. Keep view state in observable models instead of `@State`, declare environment values with an `EnvironmentKey` instead of `@Entry`, and do without `@Animatable` and `#Preview`.
- `InternalImportsByDefault` is on: an import is `package import` only when a package declaration's signature names its types. A type reached through an alias, such as `CustomMode.ID` for `UUID`, doesn't count, and Swift 6.3 rejects the unused `package import`.
- Mark only identifiers, durations, and counts `privacy: .public` in a log message. [Invariants](docs/architecture.md#invariants) lists what never reaches the log.

### Text and translations

- User-facing text uses American English and the serial comma. Messages and descriptions use sentence case; menu items and buttons use title case.
- A menu item or button ends with "…" only when the command needs more input before it completes, such as a choice, a confirmation, or a file. **Settings…** keeps it by macOS convention.
- Translate every string the code shows into every language in `Packaging/Localizations`. After you add or change one, run `make strings-update` and add it to every table; `make strings` fails until they match.
- Interpolate numbers, sizes, prices, and keyboard shortcuts into a localized string rather than typing them into it, so each language formats them and Arabic and Hebrew keep them readable.
- Arabic and Hebrew lay the interface out from right to left. Use leading and trailing rather than left and right, `.forward` and `.backward` SF Symbols, and `contentDirection(of:)` for text the user dictated.

## Tests

Tests use [Swift Testing](https://developer.apple.com/documentation/testing). Run them with `make test`: with the Command Line Tools alone, a plain `swift test` can miss Swift Testing and its macro plugins.

- Test the value types in `WaftCore` directly, adapters through small fakes of their interfaces, and the main-actor models in `WaftFeatures` with fakes of the `WaftCore` interfaces they receive.
- Tests never touch the microphone, the network, the keychain, or Accessibility, and never wait: pass fixed pauses in through the initializer, so tests set them to zero. A suite that uses a temporary pasteboard is `@MainActor`.
- Each test target keeps its own fakes and fixtures; targets share no test code.

Every test file follows one pattern:

- A suite lives in the folder that mirrors its type's folder in `Sources`, and shared doubles and fixtures live in `Fakes/` and `Fixtures/`.
- A suite tests one type: `struct <Type>Tests` in `<Type>Tests.swift`, without `@Suite`. A suite for an extension file is named after the file, such as `StringCapitalizationTests` for `String+Capitalization.swift`, and a suite that outgrows SwiftLint's limits splits by topic into `<Type><Topic>Tests`.
- A test's name is a sentence about the type in the present tense, written as a raw identifier that starts with a verb, such as `` `drops entries older than the retention` ``, in American spelling and without contractions.
- `#expect` makes every check, and `#expect(throws:)` checks errors. `#require` only unwraps a value that the rest of the test needs, in a statement of its own.
- The cases of one behavior are one test with `arguments:`, which takes an array of tuples when the test has several parameters.
- A test double is named `Fake` and the protocol it implements, such as `FakeTextRewriter`; for a protocol named after a capability, the noun replaces it, so `LicenseSignatureChecking` gets `FakeLicenseSignatureChecker`. A double that one suite uses is `private` at the bottom of that suite's file; a shared one has a file of its own.
- Fixtures that several suites share, such as `Date.fixed`, are static members in an extension of their type, in `<Type>+Fixtures.swift`. A fixture of one suite is a `private` member of that suite.
- A suite imports the module under test with `@testable` only when it uses an internal symbol.

## Shell scripts

Scripts follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) and run on the Bash 3.2 that macOS ships. A `make` target runs each one, and every script has one layout:

- `#!/bin/bash` and `set -euo pipefail`, with no comments.
- `readonly` constants, then globals, then functions: `usage` and `die`, which print to standard error, a `cleanup` trapped on `EXIT` when the script makes temporary files, a function for every step, and `main` at the bottom, called with `"$@"`.
- A function names its arguments on its first line, as in `local version=$1 image=$2`, and separates its steps with blank lines.
- A function that does work runs as a command, never inside `$(…)`, where Bash 3.2 ignores `set -e`.
- Options go before operands, long options are used where the tool has them, and argument lists that change go in an array.
- A guard reads `[[ … ]] || die …`; anything longer is an `if`.

## Documentation

Change the docs in the same pull request as the behavior they describe. Every page follows one pattern:

- A title, then a sentence that starts with "This page" and says what the page covers. README.md and AGENTS.md open with what Waft is instead.
- Each fact lives on one page, and the others link to it. Only README.md and AGENTS.md repeat what their readers need first: how to install Waft, and the commands and rules that are easy to miss.
- Leave out what the reader can't act on: history, thresholds and other internals the reader can't change, a sentence that restates its heading, and what a tool's own documentation explains.
- Headings in sentence case. Other pages, the app, the website, and release notes link to headings, so search for an anchor before you rename its heading.
- Tables for reference, numbered lists for steps, and `-` bullets for everything else. Every list item starts with a capital letter or code and ends with a period, or with a colon before a code block.
- Second person, active voice, American English, and the serial comma.
- Controls in **bold**; text Waft shows, such as a HUD message or the first line of the menu, in quotes; keys in `<kbd>`; and code, commands, and file names in code font.
- A setting is named by its control, then its place: **Editing key** in Settings › Dictation.
- Code blocks name their language, such as `sh` or `swift`.
- Inline links, relative between pages. A link to a page in `docs` or to a section uses its title as the text, and a link to any other file uses the file's name, such as [SECURITY.md](SECURITY.md).
- No dates: describe the current version. Release history lives in [GitHub Releases](https://github.com/okoflow/waft/releases).
- One line per paragraph and per list item, without hard wraps.

## Commits

Commits follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/): `type(scope): description`.

- Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, and `chore`.
- The scope names the area a change is about, from the list below. Leave it out when the change spans several areas or none of them fits.
- The description is in the imperative, starts in lowercase, stays under 72 characters, and has no trailing period. It says what the change does, not what task it closes.
- A breaking change carries `!` before the colon and a `BREAKING CHANGE:` footer that says what a user must do.
- One commit is one logical change that builds and passes on its own. Add a body only for what the diff can't show: the problem, the reason for the approach, a constraint.
- The only footers, in this order, are `Verified:` in a merge commit, `BREAKING CHANGE:`, and `Fixes #N`. No other trailers, such as `Co-authored-by:` or `Signed-off-by:`.

| Scope | Area |
| --- | --- |
| `dictation` | The dictation key, how to start, recording, hands-free dictation, and pasting |
| `languages` | Recognition, the speech model, and the rules of each language |
| `modes` | Raw, Light, Clean, Formal, Translate, your modes, and their instructions |
| `models` | The AI models and their providers |
| `edit` | Editing by voice |
| `translator` | The translator panel and the shortcuts on selected text |
| `files` | File transcription |
| `dictionary` | The dictionary and snippets |
| `history` | History and the statistics |
| `hud` | The HUD |
| `onboarding` | The setup guide |
| `settings` | The menu and Settings |
| `pro` | Waft+ and licenses |
| `ui` | The look shared across the interface, such as spacing, type, and animation |
| `l10n` | The translations of the interface |
| `release` | The version bump that prepares a release |
| `deps` | Dependency updates, which Dependabot opens |

## Pull requests

- One pull request is one standalone change. Split anything above roughly 400 changed lines unless the parts only make sense together.
- GitHub merges a pull request with a merge commit whose subject is its title and whose body is its body. Write the title in commit form and the body as a commit body: what changed and why in a few sentences, and the risky spot. End it with `Verified:` and the checks you ran, then `Fixes #N` when it closes an issue. Replace the body of a Dependabot pull request the same way before you merge it.
- Attach a screenshot or a recording of a visible change in a comment, so it stays out of the merge commit.
- CI has to pass. Reviews focus on correctness, layering, and whether the change is the smallest one that solves the problem.

## Licensing of contributions

By submitting a contribution, you agree that it is licensed under GPL-3.0-only, whose text is in [LICENSE](LICENSE), like the rest of Waft. Add your name to [AUTHORS](AUTHORS) in your first pull request to be listed among The Waft Authors.

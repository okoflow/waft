# Contributing

This page covers the setup, the checks a change passes, and the rules for
code, tests, scripts, docs, commits, and pull requests.
[Architecture](docs/architecture.md) maps the code, and
[Releasing](docs/releasing.md) covers releases. Everyone who takes part
follows the Code of Conduct in [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Ways to contribute

- **Report a bug** with the bug report form. Include the Waft and macOS
  versions, the mode, and the log lines around the problem.
- **Propose a feature** with the feature request form. Describe the problem
  before the solution.
- **Report a vulnerability** privately, as described in
  [SECURITY.md](SECURITY.md).
- **Send a pull request** for an open issue. Comment on the issue first for
  anything larger than a fix, so the approach is agreed before the work.

## Development setup

You need a Mac with Apple silicon, macOS 26.6 or later, and the Command Line
Tools for Xcode 27, which `xcode-select --install` installs.

Build and run Waft:

```sh
git clone https://github.com/okoflow/waft.git
cd waft
make signing
make run
```

`make signing` creates the Waft Dev code-signing identity in your login
keychain once and asks for your password to trust it. Without it, every build
is signed ad hoc and macOS forgets the permissions you granted. `make run`
builds the debug configuration, signs it, and opens `build/Waft.app`; add
`CONFIG=release` for an optimized build. A debug build doesn't update itself:
pull and run `make run` again.

To change the code, install the tools the checks use and the pre-commit hook:

```sh
brew bundle
make hooks
```

The [Brewfile](Brewfile) lists every [Homebrew](https://brew.sh) tool the
checks use. The hook runs `format-check`, `lint`, and `shellcheck` when the
commit touches files they check, and always runs `spelling` and
`secrets-staged`, which scans the staged changes for secrets.
`make help` lists every target.

## Checks

`make check` runs the checks below in this order, except `bundle`, which
re-signs the app you run. Run it before you push. CI runs `make check` and
then `make bundle` with the Command Line Tools for Xcode 27 on every pull
request and every push to `main`, and builds and tests with the Command Line
Tools for Xcode 26 in a second job. GitHub's CodeQL also scans the Swift code,
the cask, and the workflows.

| Target | Tool | Fails on |
| --- | --- | --- |
| `format-check` | SwiftFormat, shfmt, plutil | Any formatting difference; `make format` fixes it |
| `lint` | SwiftLint | Any violation, including comments in code, `??`, and an unbound `try?` |
| `shellcheck` | ShellCheck | Any problem in `scripts/*.sh` |
| `spelling` | typos | Spelling mistakes in code and docs |
| `secrets` | gitleaks | Secrets anywhere in the git history |
| `build` | Swift | Any warning, since warnings are errors |
| `test` | Swift Testing | A failing test |
| `periphery` | Periphery | Unused code |
| `strings` | `scripts/strings.sh` | A translation missing a string from the code, keeping one the code dropped, changing a placeholder, or lacking the microphone prompt in `InfoPlist.strings` |
| `bundle` | `scripts/bundle.sh` | The app can't be assembled or signed |

The linters and formatters read their settings from dotfiles at the root,
such as `.swiftlint.yml`, `.swiftformat`, and `.typos.toml`. Fix the code
rather than the rule. A rule that is wrong for one line gets a targeted
`// swiftlint:disable:next <rule>` or `// swiftformat:disable:next <rule>`
directive.

## Code

### Naming and files

- Name things after what they are and do, following the
  [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
  No comments in code: names, types, and small functions carry the meaning.
- Write names in full words, without abbreviations: `statisticsFile`, not
  `statsFile`; `message`, not `msg`.
- One main type per file, named after it. An extension that adds to another
  type goes into `<Type>+<Topic>.swift`, such as `String+Capitalization.swift`.
- Keep the names of Swift files unique across `Sources`: `make strings` finds
  each file's extracted strings by its name.
- Give every declaration the narrowest access level that works, and leave
  nothing unused; Periphery fails on unused code.

### Control flow

- Keep the happy path at the left margin. Check preconditions with `guard` at
  the top of a function and return or throw early; use `if` for real branches.
- Separate conditions with commas, not `&&`. Give a long condition a name, as
  a `let` or a computed property that reads as an assertion, such as
  `canSaveDraft`.
- Don't use `??`; the `no_nil_coalescing` rule enforces it. Unwrap with
  `guard let … else { return … }`, throw when absence is a failure, and use a
  dictionary's `default:` subscript for lookups.
- Don't use `try?` to hide a failure. It is fine only where absence is the
  documented result, as in `guard let key = try? PublicKey(…)`. Other failures
  are thrown or logged. The `no_optional_try` rule allows `try?` only in a
  `let` binding.
- A closed set of failures gets its own error enum, thrown with typed throws
  when every caller handles every case, as `RewriteError` is.

### Layout

- Separate the steps of a function with one blank line: the guards, the
  values it prepares, the work, and the result. A `return`, `throw`, `break`,
  or `continue` that does not open its scope gets a blank line before it,
  which the `blank_line_before_exit` rule checks. Statements of one kind stay
  together.
- A `guard` that checks a value declared on the single line directly above it
  stays under it without a blank line, and consecutive `guard`s stay together,
  as SwiftFormat requires. After any other statement of several lines, leave a
  blank line before the `guard`.
- SwiftFormat orders declarations by kind (nested types, static properties,
  instance properties, initializers, static methods, instance methods) and
  each kind from the most to the least visible.

### Platform

- The package builds with the Command Line Tools alone, which lack Xcode's
  SwiftUI macro plugins. Keep view state in observable models instead of
  `@State`, declare environment values with an `EnvironmentKey` instead of
  `@Entry`, and do without `@Animatable` and `#Preview`. The
  `no_xcode_only_macros` rule catches them, along with `@AnimatableIgnored`
  and `@Previewable`.
- Mark only identifiers, durations, and counts `privacy: .public` in a log
  message. [Invariants](docs/architecture.md#invariants) lists what never
  reaches the log.
- Animate with `.motion(_:value:)` and a `Motion` token rather than
  `.animation(_:value:)`, and pass a scoped or transition animation through
  `Motion.adapted(_:reducesMotion:)`, so Reduce Motion turns every animation
  into `Motion.reduced`. The `no_bare_animation` rule catches the plain
  modifiers.

### Text and translations

- User-facing text uses American English. Messages and descriptions use
  sentence case; menu items and buttons use title case.
- A menu item or button ends with "…" only when the command needs more input
  before it completes, such as a choice, a confirmation, or a file.
  **Settings…** keeps it by macOS convention.
- Lists of three or more use the serial comma, in the interface and in the
  docs: "Clean, Formal, and Translate".
- Translate every string the code shows into every language in
  `Packaging/Localizations`. After adding or changing one, run
  `make strings-update` and add it to every table; `make strings` fails until
  they match.
- Interpolate numbers, sizes, prices, and keyboard shortcuts into a localized
  string rather than typing them into it, so each language formats them and
  Arabic and Hebrew keep them readable.
- Arabic and Hebrew lay the interface out from right to left. Use leading and
  trailing rather than left and right, `.forward` and `.backward` SF Symbols,
  and `contentDirection(of:)` for text the user dictated.

## Tests

Tests use [Swift Testing](https://developer.apple.com/documentation/testing)
and run with `make test`, which passes `swift test` the paths of Swift Testing
and its macro plugins; with the Command Line Tools alone, a plain
`swift test` can miss them. Test the value types in `WaftCore` directly,
adapters through small fakes of their interfaces, and the main-actor models in
`WaftFeatures` with fakes of the `WaftCore` interfaces they receive. Pass
fixed pauses in through the initializer, so tests set them to zero instead of
waiting them out. Tests never touch the microphone, the network, the
keychain, or Accessibility.

Every test file follows one pattern:

- A suite tests one type: `struct <Type>Tests` in `<Type>Tests.swift`,
  without `@Suite`. A suite for an extension that a module adds to another
  module's type is named after the extension's file, such as
  `StringCapitalizationTests` for `String+Capitalization.swift`. A suite that
  outgrows SwiftLint's limits splits by topic into `<Type><Topic>Tests`, such
  as `TranscriptProcessorWritingSystemTests`.
- A test's name is a sentence about the type in the present tense, written
  as a raw identifier that starts with a verb, such as
  `` `drops entries older than the retention` ``. Names use American spelling
  and no contractions.
- `#expect` makes every check, and `#expect(throws:)` checks errors.
  `#require` only unwraps a value that the rest of the test needs, in a
  statement of its own rather than inside an `#expect`.
- The cases of one behavior are one test with `arguments:`, which takes an
  array of tuples when the test has several parameters.
- A test double is named `Fake` and the protocol it implements, such as
  `FakeTextRewriter`; for a protocol named after a capability, the noun
  replaces it, so `LicenseSignatureChecking` gets
  `FakeLicenseSignatureChecker`. A double that one suite uses is `private` at
  the bottom of that suite's file; a double that several suites share has a
  file of its own, named after it.
- Fixtures that several suites share, such as `Calendar.gmt` and
  `Date.fixed`, are static members in an extension of their type, in
  `<Type>+Fixtures.swift`. A fixture of one suite is a `private` member of
  that suite.
- A suite imports the module under test with `@testable` only when it uses
  an internal symbol.
- Each test target keeps its own fakes and fixtures; targets share no test
  code.

## Shell scripts

Scripts follow the
[Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
and run on the Bash 3.2 that macOS ships. Every script has one layout:

- `#!/bin/bash`, a header comment that says what the script does, and
  `set -euo pipefail`.
- `readonly` constants, then globals, then functions: `usage` and `die`, which
  print to standard error, a `cleanup` trapped on `EXIT` when the script makes
  temporary files, a function for every step, and `main` at the bottom, called
  with `"$@"`.
- A function names its arguments on its first line, as in
  `local version=$1 image=$2`, and separates its steps with blank lines.
- A `local` that takes a `$(…)` is declared on a line of its own, since
  `local` hides the command's failure. A function that does work runs as a
  command, never inside `$(…)`, where Bash 3.2 ignores `set -e`.
- Options go before operands, long options are used where the tool has them,
  and argument lists that change go in an array.
- A guard reads `[[ … ]] || die …`; anything longer is an `if`.

A `make` target runs each script. shfmt formats them with the settings in
`.editorconfig`, and ShellCheck checks them with those in `.shellcheckrc`.

## Documentation

Every page follows the same pattern:

- A title, then one or two sentences that say what the page covers and link
  to the pages next to it; the first starts with "This page". README.md and
  AGENTS.md open with what Waft is instead.
- Headings in sentence case. Tables for reference, numbered lists for steps,
  and `-` bullets for everything else. Every list item starts with a capital
  letter or code and ends with a period, or with a colon before a code block.
- Second person, active voice, American English.
- Controls in **bold**; text Waft shows, such as a HUD message or the first
  line of the menu, in quotes; keys in `<kbd>`; and code, commands, and file
  names in code font.
- A setting is named by its control, then its place:
  **Editing key** in Settings › Dictation.
- Code blocks name their language, such as `sh` or `swift`.
- Inline links, relative between pages. A link to a page in `docs` or to a
  section uses its title as the text, and a link to any other file uses the
  file's name, such as [SECURITY.md](SECURITY.md).
- No dates: describe the current version. Release history lives in
  [GitHub Releases](https://github.com/okoflow/waft/releases).
- Each fact lives on one page; the others link to it instead of repeating it.
- Lines wrapped at 80 columns, except in tables, code blocks, and long URLs.

Change the docs in the same pull request as the behavior they describe.

## Commits

Commits follow
[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):
`type(scope): description`.

- Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`,
  and `chore`.
- The scope names the area a change is about, from the list below. Leave it
  out when the change spans several areas or none of them fits.
- The description is in the imperative, starts in lowercase, stays under 72
  characters, and has no trailing period. It says what the change does, not
  what task it closes.
- A breaking change carries `!` before the colon and a `BREAKING CHANGE:`
  footer that says what a user must do.
- One commit is one logical change that builds and passes on its own. Add a
  body only for what the diff can't show: the problem, the reason for the
  approach, a constraint.
- The only footers, in this order, are `Verified:` in a merge commit,
  `BREAKING CHANGE:`, and `Fixes #N`. No other trailers, such as
  `Co-authored-by:` or `Signed-off-by:`.

| Scope | Area |
| --- | --- |
| `dictation` | The dictation key, how to start, recording, hands-free dictation, and pasting |
| `languages` | Recognition, the speech model, and the rules of each language |
| `modes` | Raw, Light, Clean, Formal, Translate, your modes, and their instructions |
| `models` | The AI models and their providers |
| `edit` | Editing by voice |
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

- One pull request is one standalone change. Split anything above roughly 400
  changed lines unless the parts only make sense together.
- GitHub merges a pull request with a merge commit whose subject is its title
  and whose body is its body. Write the title in commit form and the body as a
  commit body: what changed and why in a few sentences, and the risky spot.
  End it with `Verified:` and the checks you ran, then `Fixes #N` when it
  closes an issue. Replace the body of a Dependabot pull request the same way
  before merging it.
- Attach a screenshot or a recording for visible changes in a comment, so it
  stays out of the merge commit.
- CI has to pass. Reviews focus on correctness, layering, and whether the
  change is the smallest one that solves the problem.

## Licensing of contributions

Waft is licensed under the GNU General Public License v3.0 only
(GPL-3.0-only), whose text is in [LICENSE](LICENSE). By submitting a
contribution, you agree that it is licensed under the same terms. Add your name
to [AUTHORS](AUTHORS) in your first pull request to be listed among The Waft
Authors.

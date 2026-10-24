# Architecture

This page maps the code for contributors: where things live, the path a dictation takes through them, and the rules that keep them in place. [How it works](how-it-works.md) describes the same flow from the user's side, and [CONTRIBUTING.md](../CONTRIBUTING.md) how the code reads and is checked.

## Modules

```mermaid
flowchart TD
  waft[Waft<br/>composition root] --> features[WaftFeatures<br/>models · flow · views]
  waft --> platform[WaftPlatform<br/>macOS adapters · Sparkle]
  waft --> speech[WaftSpeech<br/>WhisperKit adapter]
  waft --> core
  features --> core[WaftCore<br/>domain · interfaces]
  platform --> core
  speech --> core
```

| Module | Isolation | What lives there |
| --- | --- | --- |
| `WaftCore` | Nonisolated | Domain types, text and recognition rules, state machines, and every interface between modules |
| `WaftSpeech` | Nonisolated | `WhisperTranscriber`, the decoding rules it runs with, the pieces it splits a recording into, the model files, and the language-restricted tokenizer |
| `WaftPlatform` | Nonisolated | Adapters for audio, media files, the keyboard, Accessibility, the pasteboard, storage, language detection, the AI APIs, license signatures, updates, and the system |
| `WaftFeatures` | Main actor | Observable models, the dictation flow, the HUD, the menu, Settings, onboarding, file transcription, and the translator |
| `Waft` | Main actor | The app, its delegate, and `AppDependencies.live()` |

## Code map

The tables list the folders whose names don't say enough.

**`WaftCore`** is grouped by domain:

| Folder | What lives there |
| --- | --- |
| `Keyboard` | `KeyEvent`, the `KeyEventMonitor` and `KeyboardLayout` interfaces, and `FunctionKeys`. `PushToTalk` holds `PushToTalk`, the state machine from key events to start, hands-free, finish, and discard for the chosen `DictationStart`; `RecordingTriggers`, which runs one for the dictation key and one for the editing key; and `ReleaseWatchdog`, which catches a lost key-up. `Shortcuts` holds `ShortcutAction`, `KeyCombination`, and `ShortcutSettings`, the global shortcuts and their defaults |
| `Speech` | `Model` holds `SpeechModel` and `SpeechModelState`, whose transitions return the effects a controller runs. `Recognition` holds the `Transcriber` interface, `SpeechGate`, `WhisperPrompt`, and `HallucinationFilter` with its `StockPhrase` rows. `Files` holds `MediaDecoder`, `TimedTranscript`, and `SubtitleFormatter` |
| `Language` | `Language` with its names, typography, and sound-alike languages. `Writing` holds the writing systems and the `WritingVariants` for Chinese and Serbian, with `SerbianCyrillic` |
| `Text` | String rules that several features share. `LightMode` holds Light mode: `LightModeRules`, `HesitationRemover`, and `VoiceCommands` |
| `Settings` | `Settings`; `Settings+Modes`, which lists every mode and turns one into a `RewriteSetup`; `Settings+Shortcuts`, which finds the shortcut or key a new combination conflicts with; and `Settings+Translator`, which does the same as `Settings+Modes` for a `TextTask` and lists the languages the translator expects |
| `Rewrite` | `TranscriptProcessor`, which runs the dictionary, the mode, and the AI model under a deadline, and reworks typed text for a `TextTask`; `RewriteError` and `RewriteFallback`; and `Translation`, the target of Translate and the translator. `Providers` holds the providers, `CloudModel`, and the `TextRewriter` interface. `Prompt` holds `RewriteRequest`, `RewritePrompt`, and `RewriteValidator` |
| `Translator` | `TextTask`, the work the translator does on typed text, and `TranslatorSettings`: the translator's languages and recent languages, when a chosen source gives way, where text goes and how a swap turns the pair, its model tier, and the edited instructions of each `TextTask` |
| `Insertion` | The `TextInserter` interface, and whether and how to paste: focus comparison, spacing, and restoring the clipboard |
| `Storage` | The `ValueStore` interface and, in `KeyedDecodingContainer+Defaults`, the lenient decoding that keeps one bad field from resetting the rest |
| `Support` | `Poll`, `Task.slept`, `Uptime`, and the other helpers that every module uses, such as `Error.logDescription` |

**`WaftPlatform`** implements the interfaces in a folder per area, such as `KeyEventTap` in `Keyboard`, `AudioEngineRecorder` in `Audio`, and `PasteboardInserter` in `Pasteboard`.

- `Rewrite` holds `HTTPRewriter`, which sends a rewrite through an API description per service in `Providers` (`AnthropicAPI`, `OpenAIAPI`, and `ChatCompletionsAPI` for local servers) over the transport in `HTTP`, and `LocalServerBrowser`, which lists a local server's models.
- `Storage` holds `JSONFileStore`, which keeps its folder and files owner-only and a copy of a file it can't read, so a later save doesn't destroy it. `SecretFileStore` keeps an API key or the license key in a `JSONFileStore` and moves a key an older version left in the keychain into it on first load through `KeychainStore`, which nothing else uses. `ValueStore+Logging` in `WaftFeatures/Support` logs persistence failures.
- `Updates` holds `SparkleUpdater`, which turns itself off when `Info.plist` has no `SUFeedURL`. `scripts/bundle.sh` removes the key from debug bundles.

**`WaftFeatures`** is grouped by feature:

| Folder | What lives there |
| --- | --- |
| `App` | `AppDependencies`; `AppModel`, which builds every model from them and wires the models together; `WindowPresenter`, which opens Settings, the setup guide, file transcription, and the translator, and gives Waft a Dock icon while one of the first three is open or Sparkle shows an update |
| `Models` | The observable state that several features share, including `PermissionMonitor` and `GlobalShortcutController`, which registers the global shortcuts again when they change; a model that one screen uses lives with that screen |
| `Dictation` | The controllers of [the dictation flow](#the-dictation-flow) and the values they pass along |
| `HUD` | `HUDController` and `HUDPanel`, the HUD at the notch, at the top of the screen, or below the menu bar when `ForeignWindow` finds another app's window over the notch; `Island` holds the views inside it |
| `MenuBar` | `MenuBarScene`, the menu bar icon (the W mark), and the menu |
| `Settings` | `Window` holds the Settings window and its sidebar, a folder per pane holds that pane, and `Shared` holds what several panes or the setup guide use, such as `TryoutModel`, `AIModelSetup`, and `ShortcutRow` |
| `Translator` | `Panel` holds `TranslatorModel` behind the translator; `TranslatorPanel`, the floating panel that opens over the app in front without activating Waft and closes when you leave it; and `CopyableText`, the translation that copies itself on a click. `Selection` holds `SelectionActions`, which reads the selected text through Accessibility, or copies it through the `TextInserter`, and translates or fixes it, and `TranslatorShortcuts`, which handles its three shortcuts |
| `DesignSystem` | `Tokens` (colors, metrics, motion, and fonts), `Brand` (the icon and the Waft+ marks), `Controls`, `Rows` (the cards, sections, and rows of Settings and the setup guide), and view `Modifiers` |
| `Support` | Logging, timers, and display helpers that several features share |

**`Tests`** has a Swift Testing target for every module but `Waft`, with its suites in the folders of `Sources` and its shared doubles and fixtures in `Fakes` and `Fixtures`; see [Tests](../CONTRIBUTING.md#tests).

**`Packaging`** holds the rest of the app bundle: `Waft-Info.plist`, the entitlements, the icon, the translations, the start and stop sounds, and the Homebrew cask template. **`scripts`** holds the shell scripts that `make` runs.

## The dictation flow

1. `PermissionMonitor` polls the microphone and Accessibility status once a second while one is missing and every 30 seconds once both are granted, since each check of the microphone asks macOS's privacy service; opening a window checks them at once. A change moves onboarding on and makes `KeyMonitorController` start the `KeyEventMonitor` if it isn't running. The controller also restarts a monitor that stops, and `KeyEventTap` turns itself back on when macOS switches it off.
2. `DictationController` feeds the monitor's key events to `RecordingTriggers` and hands finished recordings to the queue. `RecordingController` starts and stops the `AudioRecorder`, polls `ReleaseWatchdog` for a lost key-up, and captures the focus target.
3. `DictationQueue` runs finished recordings one at a time: the `Transcriber` recognizes them, `TranscriptProcessor` applies the dictionary, snippets, and the mode, and the `TextInserter` pastes the result.
4. An AI mode runs the `TextRewriter` under the deadline of the chosen `CloudModel` or the local server, validates the answer with `RewriteValidator`, and on any `RewriteError` falls back to Light with a `RewriteFallback` that says why.
5. An edit by voice gives Whisper the dictionary terms but skips their replacements, the snippets, and the mode: `TranscriptProcessor.edit` sends the selection read at the key press and the spoken instruction to the `TextRewriter`, and the answer replaces the selection. A failure pastes nothing.
6. The outcome becomes a `HUDMessage`. The text becomes the latest transcript, even in a password field, and text that is pasted or copied becomes a history entry unless it came from an edit.

## Invariants

- Dependencies point toward `WaftCore`, which imports Foundation only and builds with strict memory safety. `WaftFeatures` never imports an adapter module; it sees adapters through the interfaces in `WaftCore`.
- Only `AppDependencies.live()` names concrete adapters. There are no singletons.
- Declarations shared between modules are `package`, never `public`. Imports follow the `InternalImportsByDefault` rule in [Platform](../CONTRIBUTING.md#platform).
- Rules that need no system access are value types in `WaftCore`.
- `WhisperTranscriber`, `AudioEngineRecorder`, and `MediaAudioReader` are actors, so recognition, audio, and media files stay off the main actor. The last two run on serial dispatch queues of their own, so their blocking calls never hold a thread of the cooperative pool.
- Audio, dictated text, and clipboard contents never reach the log or the disk, apart from the history the user keeps.
- User-facing strings use `String(localized:)` or `LocalizedStringKey`, even the names of domain values in `WaftCore`. Choosing a language in Waft writes `AppleTextDirection` next to `AppleLanguages`, so Arabic and Hebrew lay out right to left.

## Third-party packages

The package depends only on WhisperKit, from `argmax-oss-swift`, and Sparkle, pinned to exact versions in `Package.swift`, with every resolved package recorded in `Package.resolved`. Dependabot proposes updates for them and for the GitHub Actions. These candidates were rejected:

| Package | Why not |
| --- | --- |
| KeyboardShortcuts | No modifier-only or Fn push-to-talk, and a resource bundle the app would have to copy |
| LaunchAtLogin | Only wraps what `MainAppLoginItem` does |
| Defaults | Would replace `ValueStore` and the lenient decoding in `KeyedDecodingContainer+Defaults` |
| swift-dependencies | Brings macros and swift-syntax for what `AppDependencies` already does |
| swift-log | Loses the privacy redaction of `os.Logger` |

## Extending

To add a language:

1. Add a case to `Language` with its Whisper code.
2. Add its names in `Language+Names` and its writing systems in `Language+Typography`, where a period or question mark of its own also goes. Letter case and word spacing follow from the `WritingScript`.
3. If it has marks that comparisons ignore, list them in `Language+Folding`.
4. Add its rows: hesitation sounds in `HesitationPattern`, stock phrases in `StockPhrase`, voice commands in `VoiceCommands`, and the example sentence in `WhisperPrompt`.
5. If it sounds like another language, add a group in `Language+SoundAlike`.

To add anything else:

- **A mode.** Add a case to `Mode` with its title, summary, and the raw value it is stored under, and list it in `Mode.builtIn`. An AI mode needs its instruction in `RewritePrompt`.
- **An AI provider.** Describe its API in `WaftPlatform/Rewrite/Providers` as a `RewriteAPI` with a model identifier for each `CloudModel`, add a `CloudProvider` case, a `PerProvider` property, the names of its models in `CloudProvider+Display`, and its key file in `SecretFileStore.apiKey(for:)`, wire it in `Rewriters.http`, and list its file in [What Waft keeps](privacy.md#what-waft-keeps).
- **An adapter.** Implement the interface in `WaftPlatform` and pass it in `AppDependencies.live()`.

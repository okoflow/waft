# Troubleshooting

This page says what to do when something doesn't work, starting from what the HUD or the first line of the menu says. [Usage](usage.md) describes the settings named here, and [Privacy](privacy.md) the files Waft keeps. Quoted text is what the HUD shows.

## macOS won't open Waft

When macOS says it can't verify that Waft is free of malware, allow it once with **Open Anyway**, as [Install](getting-started.md#1-install) shows.

## macOS asks for your password for the keychain

When macOS asks for your password because Waft wants to use confidential information stored in `com.okoflow.waft` in your keychain, Waft is moving an API key or the license key that an older version kept there into its file, as [What Waft keeps](privacy.md#what-waft-keeps) describes. Enter your password and click **Allow**: Waft deletes the item from the keychain and doesn't ask again. If you click **Deny**, the key stays in the keychain and Waft works as if it had none until you allow it or add the key again in Settings.

## The dictation or editing key does nothing

| Symptom | Fix |
| --- | --- |
| The menu says "Setup needed" | Choose **Finish Setup…** or click **Allow…** in Settings › General |
| "Waft can't use the microphone. Allow it in Settings › General." | Click **Allow…** next to Microphone |
| "Editing by voice is part of Waft+." or "Translating and fixing text is part of Waft+." | Add a license in Settings › Waft+ |
| The menu or the HUD shows the speech model downloading or preparing | Wait; [The speech model](how-it-works.md#the-speech-model) says how long it takes |
| The menu says "Speech model failed" | See [The speech model fails](#the-speech-model-fails) |
| The editing key shows "None" | There's none by default: set **Editing key** in Settings › Dictation |
| Another key is set | The first line of the menu and **Dictation key** in Settings › Dictation show which one |
| <kbd>🌐</kbd> opens emoji or dictation | Set **Press 🌐 key to** to **Do Nothing** in System Settings › Keyboard |
| A function key acts as a media key | Turn on **Use F1, F2, etc. keys as standard function keys** in System Settings › Keyboard › Keyboard Shortcuts › Function Keys |
| A shortcut does nothing | It shows "None" and is off, or Settings says "Unavailable: another app uses this shortcut. Choose another one." under it; [Shortcuts](usage.md#shortcuts) says how to change it |
| The menu bar icon is missing | Turn on **Show in menu bar** in Settings › General, and on macOS 26 and later allow Waft in System Settings › Menu Bar. A crowded menu bar can hide the icon behind the notch |

## The text isn't pasted

| Symptom | Cause and fix |
| --- | --- |
| The HUD shows the text with <kbd>⌘</kbd><kbd>V</kbd> | **Paste into the focused field** is off in Settings › Writing, focus moved, Accessibility isn't allowed, the app was slow to take the text, or you held the key over 10 seconds; [Pasting](how-it-works.md#pasting) has the details |
| "Not pasted into a password field" | A password field, or an app that holds secure keyboard input so Waft can't see the field; **Copy Last Dictation** in the menu gets a dictation back within 10 minutes |
| "Didn't catch that" | The recording held no speech or only hesitations, or Whisper's result looked made up |
| "Recording failed" or "Transcription failed" | The microphone or the speech model failed; the line below says why |
| "Couldn't edit the text", "Couldn't translate the text", or "Couldn't fix the text" | The selection stays as it was; the line below is a reason from [The AI modes use Light](#the-ai-modes-use-light) |
| "Select the text to edit, then hold the key and say what to change." | Nothing is selected, or the app, such as a web view, doesn't expose it to Accessibility |
| "Select the text first, then press the shortcut." | Nothing is selected, or the app didn't copy the selection when Waft pressed <kbd>⌘</kbd><kbd>C</kbd>; [The translator](how-it-works.md#the-translator) has the details |
| The text has no leading space | The app, such as an Electron app, a game, or a remote desktop, exposes little to Accessibility, so Waft can't see the text before the cursor |

## Recognition is poor or picks the wrong language

| Symptom | Fix |
| --- | --- |
| The first word is cut off | The microphone takes a moment to start: speak a beat after you press the key |
| The wrong language | Enable only the languages you speak in Settings › Dictation, or choose one as the **Spoken language**; [Languages](usage.md#languages) names those that get mixed up |
| Names and terms come out wrong | Add them to the dictionary, with the spellings Whisper writes under **Heard as** |
| It hears the wrong microphone | Set **Microphone** in Settings › Dictation to the one you speak into |

## The AI modes use Light

The HUD shows "Without AI" next to the check mark. Pointing at it shows the text with "Used Light mode:" and a reason, as does the text Waft couldn't paste, with your provider's name in place of *provider*. The next dictation tries the AI model again. The `network` log category records the HTTP status or the connection error of a failed request, as [Logs](#logs) shows.

| The reason | Fix |
| --- | --- |
| add your *provider* API key in Settings › AI Models | Add the key there |
| choose a local server and model in Settings › AI Models | Choose both there; if both are set, choose a model the server lists under **Model** |
| AI modes need Waft+ | Add a license in Settings › Waft+ |
| you're offline | Check your connection |
| the local server isn't running | Start it, then click **Check** in Settings › AI Models |
| *provider* didn't answer in time | Choose a quicker model if it keeps happening; [Choosing the AI model](usage.md#choosing-the-ai-model) lists each time limit |
| *provider* is rate-limiting requests | Wait a moment; with OpenAI, the account may be out of credit |
| *provider* rejected the API key | Create a new key as [Choosing the AI model](usage.md#choosing-the-ai-model) describes |
| *provider* isn't available | The model doesn't exist, or the secure connection failed |
| *provider* returned an error | With Claude, the usual cause is a key created outside a workspace |
| *provider*'s answer couldn't be used | The answer was empty, cut off, refused, too long, or in another script; dictate again. If one of your modes always fails, its instructions ask for more than [The AI modes](how-it-works.md#the-ai-modes) allows |

## The speech model fails

**Retry Speech Model** in the menu resumes a failed download or loads the model again; if the load fails twice, the next retry deletes the model and downloads it anew. A download also fails without enough free space; [The speech model](how-it-works.md#the-speech-model) says how much. To start over by hand, quit Waft and remove the model and its compiled copy, which [What Waft keeps](privacy.md#what-waft-keeps) locates:

```sh
rm -r ~/Library/Application\ Support/Waft/Models ~/Library/Caches/com.okoflow.waft
```

## The dictionary, history, or statistics disappeared

When Waft can't read `dictionary.json`, `history.json`, or `stats.json`, for example after a hand edit with a typo, it saves a copy beside it as `dictionary.unreadable.json` and so on, then starts empty. Fix the copy and move it back while Waft isn't running.

## Logs

Waft logs what it did and how long it took, and why an AI mode fell back to Light; [Logs](privacy.md#logs) lists what it never logs. Use `/usr/bin/log`, since zsh has a `log` command of its own, to watch the log live or show the last ten minutes:

```sh
/usr/bin/log stream --level info --predicate 'subsystem == "com.okoflow.waft"'
/usr/bin/log show --last 10m --info --predicate 'subsystem == "com.okoflow.waft"'
```

When a dictation lost words, the `dictation` category gives the seconds of audio and the characters Whisper recognized and the mode returned, and the `speech` category says how many pieces Waft split the recording into and which piece gave no text, ran out of decoder tokens, or had segments dropped as unsure or made up.

Attach the lines around the problem to a bug report.

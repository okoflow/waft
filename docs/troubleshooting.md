# Troubleshooting

This page covers what to do when the first line of the menu or the HUD
reports a problem. [Usage](usage.md) describes each setting named here, and
[Privacy](privacy.md) lists the files Waft keeps.

## The dictation key does nothing

- **The menu says "Setup needed".** A permission is missing. Choose **Finish
  Setup…**, or allow it in Settings › General › Permissions.
- **The menu shows the speech model.** Waft records nothing until the model
  is ready. The first load takes about a minute.
- **Another key is set.** The first line of the menu and Settings ›
  Dictation › **Dictation key** show which key Waft listens for.
- **Fn opens emoji or dictation.** With Fn (🌐) as the key, set **Press 🌐 key
  to** to **Do Nothing** in System Settings › Keyboard.
- **A function key does nothing.** F1–F12 act as media keys unless **Use F1, F2,
  etc. keys as standard function keys** is on in System Settings › Keyboard ›
  Keyboard Shortcuts › Function Keys.
- **Permissions were lost after a rebuild.** A build signed ad hoc gets a new
  identity every time, and macOS forgets what you allowed. Run `make signing`
  once, rebuild, remove the old Waft entries in System Settings › Privacy &
  Security, and allow them again.

## The menu bar icon is missing

On macOS 26 and later, check that Waft is allowed in System Settings › Menu
Bar. On a crowded menu bar, the icon can hide behind the camera notch.
Opening Waft again while it runs shows Settings.

## The text isn't pasted

| The HUD says | What happened |
| --- | --- |
| Copied: press ⌘V to paste | Focus moved to another app or field, Accessibility isn't allowed, the app didn't take the text within 1.5 seconds, or you held the dictation key for 10 seconds after the text was ready |
| Not pasted into a password field | The field is a password field, or an app holds secure keyboard input; **Copy Last Dictation** gets the text back |
| Didn't catch that | The recording held no speech, or Whisper's result looked made up |
| Recording failed | The microphone stopped or delivered no audio; the line below it says why |
| Transcription failed | The speech model couldn't recognize the recording; the line below it says why |

If Waft never pastes, check **Paste into the focused field**, as
[Settings](usage.md#settings) describes.

## The first word is cut off

The microphone takes a moment to start; [Limits](how-it-works.md#limits) says
when to start speaking.

## Recognition is poor or picks the wrong language

- Enable only the languages you speak in Settings › Dictation, or choose one
  as the **Spoken language**.
- Choose the microphone you speak into in Settings › Dictation ›
  **Microphone**.
- Add names and terms that come out wrong to the dictionary, with the
  spellings Whisper writes under **Heard as**.
- Languages that sound alike get mixed up when you enable them together.
  Choose the one you speak as the **Spoken language**, as
  [Languages](usage.md#languages) describes.

## The AI modes use Light

The second line of the HUD starts with "Used Light mode:" and says why, with
the name of your provider in place of *provider*:

| The HUD says | What to do |
| --- | --- |
| add your *provider* API key in Settings › AI Models | Add the key there |
| choose a local server and model in Settings › AI Models | Choose both there |
| AI modes need Waft Pro | Add a license in Settings › Waft Pro |
| you're offline | Nothing: the next dictation tries again |
| the local server isn't running | Start Ollama, LM Studio, or your server, and click **Check** in Settings › AI Models |
| *provider* didn't answer in time | Nothing: the next dictation tries again |
| *provider* is rate-limiting requests | Wait a moment. With OpenAI, it can also mean the account is out of credit; the `network` log category then says `insufficient_quota` |
| *provider* rejected the API key | Check the key in the [Anthropic Console](https://console.anthropic.com/settings/keys) or the [OpenAI dashboard](https://platform.openai.com/settings/organization/api-keys) and paste it again |
| *provider* isn't available | The API answered that the model doesn't exist, or the secure connection to it failed; the `network` log category records the reason |
| *provider* returned an error | The `network` log category records the reason. With Claude, the usual one is a key created outside a workspace: create one inside a workspace in the Anthropic Console |
| *provider*'s answer couldn't be used | The answer was empty, cut off, refused, too long, or in another script; dictating again usually works. If one of your modes fails every time, its instructions ask for a longer text than [The AI modes](how-it-works.md#the-ai-modes) allows |

## The speech model fails

**Retry Speech Model** in the menu resumes a failed download. After a failed
load, it loads the model again, and if that fails too, it deletes the model
and downloads it anew. The Fast model needs about 1 GB of free space, including
its compiled copy, and switching to the Accurate one about 4 GB.

To start over by hand, quit Waft and remove the model:

```sh
rm -r ~/Library/Application\ Support/Waft/Models ~/Library/Caches/com.okoflow.waft
```

## The dictionary, history, or statistics disappeared

When `dictionary.json`, `history.json`, or `stats.json` can't be read, for
example after a hand edit with a typo, Waft saves a copy next to it as
`dictionary.unreadable.json` and so on, then starts empty. Fix the copy and
move it back while Waft isn't running.

## Logs

Waft logs what it does, never what you said. Watch the log live while you
dictate, or show the last ten minutes:

```sh
log stream --level info --predicate 'subsystem == "com.okoflow.waft"'
log show --last 10m --info --predicate 'subsystem == "com.okoflow.waft"'
```

Attach the relevant lines to a bug report.

# Troubleshooting

This page says what to do when something doesn't work, starting from what the
first line of the menu or the HUD reports. [Usage](usage.md) describes each
setting named here, and [Privacy](privacy.md) lists the files Waft keeps.

## The dictation or editing key does nothing

- **The menu says "Setup needed".** A permission is missing. Choose
  **Finish Setup…**, or click **Allow…** next to it in Settings › General.
- **The HUD says "Waft can't use the microphone."** Click **Allow…** next to
  Microphone in Settings › General.
- **The menu shows the speech model's progress.** Wait for the download and
  the first load to finish;
  [The speech model](how-it-works.md#the-speech-model) says how long the load
  takes.
- **Another key is set.** The first line of the menu and **Dictation key** in
  Settings › Dictation show which key Waft listens for.
- **Fn opens emoji or dictation.** With <kbd>🌐</kbd> as the key, set
  **Press 🌐 key to** to **Do Nothing** in System Settings › Keyboard.
- **A function key does nothing.** <kbd>F1</kbd>–<kbd>F12</kbd> act as media
  keys unless **Use F1, F2, etc. keys as standard function keys** is on in
  System Settings › Keyboard › Keyboard Shortcuts › Function Keys.
- **The HUD says "Editing by voice is part of Waft Pro."** Add a license in
  Settings › Waft Pro.
- **Permissions were lost after a rebuild.** Run `make signing` once, as
  [Development setup](../CONTRIBUTING.md#development-setup) describes,
  rebuild, remove the old Waft entries in System Settings › Privacy &
  Security, and allow them again.

## The menu bar icon is missing

If you turned off **Show in menu bar**, turn it back on as
[The menu](usage.md#the-menu) describes. On macOS 26 and later, also check
that Waft is allowed in System Settings › Menu Bar. On a crowded menu bar, the
icon can hide behind the camera notch.

## The text isn't pasted

| The HUD says | What it means and what to do |
| --- | --- |
| Copied: press ⌘V to paste | **Paste into the focused field** is off in Settings › Writing, focus moved to another app or field, Accessibility isn't allowed, the app didn't take the text in time, or you held the key too long after the text was ready; [Pasting](how-it-works.md#pasting) gives the limits |
| Not pasted into a password field | The field is a password field, or an app holds secure keyboard input and Waft can't see the field; **Copy Last Dictation** gets the text back |
| Didn't catch that | The recording held no speech or only hesitations, or Whisper's result looked made up |
| Recording failed | The microphone stopped or delivered no audio; the line below it says why |
| Transcription failed | The speech model couldn't recognize the recording; the line below it says why |
| Couldn't edit the text | An edit by voice failed and the selection stays as it was; the line below it gives one of the reasons in [The AI modes use Light](#the-ai-modes-use-light) |
| Select the text to edit, then hold the key and say what to change. | The editing key found no selection: select text first. Some apps, such as some web views, don't expose it to Accessibility |

## Recognition is poor or picks the wrong language

- If the first word is cut off, [Limits](how-it-works.md#limits) says when to
  start speaking.
- Enable only the languages you speak in Settings › Dictation, or choose one
  as the **Spoken language**; [Languages](usage.md#languages) names those that
  get mixed up.
- Set **Microphone** in Settings › Dictation to the microphone you speak into.
- Add names and terms that come out wrong to the dictionary, with the
  spellings Whisper writes under **Heard as**.

## The AI modes use Light

Under the text, the HUD adds a line that starts with "Used Light mode:" and
says why, with the name of your provider in place of *provider*:

| The HUD says | What it means and what to do |
| --- | --- |
| add your *provider* API key in Settings › AI Models | Add the key there |
| choose a local server and model in Settings › AI Models | Choose both there. If both are set, the server answered that it has no such model: choose one it lists under **Model** |
| AI modes need Waft Pro | Add a license in Settings › Waft Pro |
| you're offline | Nothing: the next dictation tries again |
| the local server isn't running | Start Ollama, LM Studio, or your server, and click **Check** in Settings › AI Models |
| *provider* didn't answer in time | The next dictation tries again. If it keeps happening, choose a quicker model; [The AI modes](how-it-works.md#the-ai-modes) lists each time limit |
| *provider* is rate-limiting requests | Wait a moment. With OpenAI, it can also mean the account is out of credit; the `network` log category then says `insufficient_quota` |
| *provider* rejected the API key | Check the key in the [Anthropic Console](https://console.anthropic.com/settings/keys) or the [OpenAI dashboard](https://platform.openai.com/settings/organization/api-keys) and paste it again |
| *provider* isn't available | The API answered that the model doesn't exist, or the secure connection to it failed; the `network` log category records the reason |
| *provider* returned an error | The `network` log category records the reason. With Claude, the usual one is a key created outside a workspace: create one inside a workspace in the Anthropic Console |
| *provider*'s answer couldn't be used | The answer was empty, cut off, refused, too long, or in another script; dictating again usually works. If one of your modes fails every time, its instructions ask for a longer text than [The AI modes](how-it-works.md#the-ai-modes) allows |

## The speech model fails

**Retry Speech Model** in the menu resumes a failed download. After a failed
load, it loads the model again; if that load fails too, the next retry deletes
the model and downloads it anew. A download also fails without the free space
that [Install](getting-started.md#1-install) lists.

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

Watch the log live while you dictate, or show the last ten minutes;
[Logs](privacy.md#logs) lists what Waft writes there. Use `/usr/bin/log`, since
zsh has a `log` command of its own:

```sh
/usr/bin/log stream --level info --predicate 'subsystem == "com.okoflow.waft"'
/usr/bin/log show --last 10m --info --predicate 'subsystem == "com.okoflow.waft"'
```

Attach the lines around the problem to a bug report.

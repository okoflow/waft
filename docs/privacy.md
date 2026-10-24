# Privacy

This page lists what Waft keeps on your Mac, where, and when it uses the network. [How it works](how-it-works.md) follows a dictation step by step, and [Troubleshooting](troubleshooting.md) shows how to read the log.

## Audio

Waft records only while you hold the dictation or editing key or while hands-free dictation runs, and keeps the audio in memory until Whisper has recognized it. It then discards the audio and never writes it to disk or sends it anywhere, in any mode; files you transcribe stay where they are.

## The network

Waft connects to these services, and only for these reasons:

| Service | When | What is sent |
| --- | --- | --- |
| Hugging Face | Downloading the speech model you choose | Requests for the model files and the Whisper tokenizer |
| GitHub | Checking for updates, unless you turn it off, and downloading them | A request for the update feed that names the Waft version |
| The AI provider you chose: Claude, OpenAI, or your local server | Clean, Formal, Translate, your modes, **Try it**, edits by voice, and the translator | The recognized text, the selected text for an edit, or the text you translate or fix; the instructions; the spoken, source, and target languages that apply; and the Claude or OpenAI API key |
| Your local server | Settings › AI Models lists its models, and **Detect** looks for one on ports 11434, 1234, 8080, and 1337 of this Mac | Requests for its list of models, sent only to the address you set or those ports |

Raw and Light never use the network, and the translator detects languages on your Mac. Waft asks OpenAI not to store the response (`store: false`). Anthropic's [privacy policy](https://www.anthropic.com/legal/privacy) and OpenAI's [API data controls](https://developers.openai.com/api/docs/guides/your-data) describe how each handles the text.

## What Waft keeps

| What | Where |
| --- | --- |
| Settings, the app language, the trial start, and the updater's state | The `com.okoflow.waft` preferences domain |
| Dictionary and snippets | `~/Library/Application Support/Waft/dictionary.json` |
| Daily word, dictation, and time counts for the statistics, no text | `~/Library/Application Support/Waft/stats.json` |
| History, with the mode and app of each dictation, as long as **Keep dictations for** allows | `~/Library/Application Support/Waft/history.json` |
| Speech model | `~/Library/Application Support/Waft/Models` |
| The model compiled for your chip, and cached responses and cookies from update checks and model downloads | `~/Library/Caches/com.okoflow.waft`, `~/Library/HTTPStorages/com.okoflow.waft`, and `~/Library/HTTPStorages/com.okoflow.waft.binarycookies` |
| Claude and OpenAI API keys and the Waft+ license key | The login keychain, service `com.okoflow.waft`, on this Mac only |

Only you can read the dictionary, statistics, and history files. If Waft can't read one of them, it keeps an `*.unreadable.json` copy beside it, which **Clear History…** in Settings › History also deletes for the history. [Troubleshooting](troubleshooting.md#the-dictionary-history-or-statistics-disappeared) says how to recover it.

**Copy Last Dictation** keeps your last text in memory only, never on disk. Edits by voice, what the translator translates or fixes, file transcriptions, and text that Waft kept out of a password field stay out of the history and the statistics.

Waft marks the text it puts on the clipboard as transient and concealed, so clipboard managers that follow the [nspasteboard.org](http://nspasteboard.org) conventions don't store it, and Universal Clipboard skips it.

When the [shortcuts on selected text](usage.md#selected-text) copy the selection with <kbd>⌘</kbd><kbd>C</kbd>, the app, not Waft, puts it on the clipboard, so a clipboard manager may store it.

## Logs

The unified log, under the `com.okoflow.waft` subsystem, never contains the dictated text, the audio, or the clipboard contents. [Logs](troubleshooting.md#logs) has the commands to read it.

## Removing everything

If you installed Waft with Homebrew, `brew uninstall --zap --cask waft` quits it and removes the app, its files, and its settings. Otherwise, quit Waft, delete the app, and run:

```sh
rm -rf ~/Library/Application\ Support/Waft ~/Library/Caches/com.okoflow.waft \
  ~/Library/HTTPStorages/com.okoflow.waft ~/Library/HTTPStorages/com.okoflow.waft.binarycookies
defaults delete com.okoflow.waft
```

Either way, remove the API keys and the license key from the keychain, and the permissions you granted:

```sh
security delete-generic-password -s com.okoflow.waft -a anthropic-api-key
security delete-generic-password -s com.okoflow.waft -a openai-api-key
security delete-generic-password -s com.okoflow.waft -a license-key
tccutil reset All com.okoflow.waft
```

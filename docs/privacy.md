# Privacy

This page lists what Waft keeps on your Mac, where, and when it uses the
network. [How it works](how-it-works.md) follows a dictation step by step, and
[Troubleshooting](troubleshooting.md) shows how to read the log.

## Audio

Waft records only while you hold the dictation or editing key, or while
hands-free dictation runs. It keeps the audio in memory until Whisper has
recognized it, then discards it; it never writes audio to disk or sends it
anywhere, in any mode. Files you transcribe stay where they are, and Whisper
recognizes them on your Mac the same way.

## The network

Waft connects to these services, and only for these reasons:

| Service | When | What is sent |
| --- | --- | --- |
| Hugging Face | Downloading the speech model you choose | Requests for the model files and the Whisper tokenizer |
| GitHub | Checking for updates, unless you turn it off, and downloading them | A request for the update feed that names the Waft version |
| The AI provider you chose: Claude, OpenAI, or your local server | Clean, Formal, Translate, your modes, **Try it**, and edits by voice | The recognized text, the mode's instructions, the spoken language, the target language when translating, the selected text for an edit, and the Claude or OpenAI API key |
| Your local server | Settings › AI Models lists its models, and **Detect** looks for one on ports 11434, 1234, 8080, and 1337 of this Mac | Requests for its list of models, sent only to the address you set or those ports |

Raw and Light never use the network. Waft asks OpenAI not to store the
response (`store: false`). Anthropic's
[privacy policy](https://www.anthropic.com/legal/privacy) and OpenAI's
[API data controls](https://developers.openai.com/api/docs/guides/your-data)
describe how each handles the text.

## What Waft keeps

| What | Where |
| --- | --- |
| Settings | The `com.okoflow.waft` preferences domain |
| Dictionary and snippets | `~/Library/Application Support/Waft/dictionary.json` |
| Word, dictation, and time counts per day for the statistics, no text | `~/Library/Application Support/Waft/stats.json` |
| History, as long as **Keep dictations for** allows | `~/Library/Application Support/Waft/history.json`, readable only by you |
| Speech model | `~/Library/Application Support/Waft/Models` |
| The model compiled for your chip, and cached responses from update checks and model downloads | `~/Library/Caches/com.okoflow.waft` |
| Cookies and other HTTP data from update checks and model downloads | `~/Library/HTTPStorages/com.okoflow.waft` and `~/Library/HTTPStorages/com.okoflow.waft.binarycookies` |
| Claude and OpenAI API keys and the Waft Pro license key | The login keychain, service `com.okoflow.waft`, on this Mac only |

**Copy Last Dictation** keeps your last text in memory only, never on disk.
Edits by voice, and text that Waft kept out of a password field, stay out of
the history and the statistics.

Waft marks the text it puts on the clipboard, pasted or copied, as transient
and concealed, so clipboard managers that follow the
[nspasteboard.org](http://nspasteboard.org) conventions don't store it, and
it stays off Universal Clipboard.

## Logs

Waft writes to the unified log under the `com.okoflow.waft` subsystem: what it
did and how long it took, the microphone, the language and the mode, why an AI
mode fell back to Light, and the app it pasted into and how many characters.
The dictated text, the audio, and the clipboard never reach the log.

## Removing everything

Quit Waft, delete the app, and run:

```sh
rm -rf ~/Library/Application\ Support/Waft ~/Library/Caches/com.okoflow.waft \
  ~/Library/HTTPStorages/com.okoflow.waft ~/Library/HTTPStorages/com.okoflow.waft.binarycookies
defaults delete com.okoflow.waft
security delete-generic-password -s com.okoflow.waft -a anthropic-api-key
security delete-generic-password -s com.okoflow.waft -a openai-api-key
security delete-generic-password -s com.okoflow.waft -a license-key
tccutil reset All com.okoflow.waft
```

The `security` commands remove the API keys and the license key, and
`tccutil` removes the permissions you granted.

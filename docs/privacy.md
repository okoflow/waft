# Privacy

This page lists what Waft keeps on your Mac, where, and when it uses the
network. [How it works](how-it-works.md) follows a dictation step by step.

## Audio

Audio is recorded only while you hold the dictation or editing key, or while
hands-free dictation runs. It stays in memory until Whisper has recognized it
and is then discarded. It is never written to disk and never sent anywhere,
in any mode. Files you transcribe are read where they are, recognized on your
Mac in the same way, and never uploaded.

## The network

Waft connects to these services, and only for these reasons:

| Service | When | What is sent |
| --- | --- | --- |
| Hugging Face | Downloading the speech model you choose, once per model | Requests for the model files |
| GitHub | Checking for updates, once a day unless you turn it off, and downloading them | A request for the update feed that names the Waft version |
| Anthropic API | Clean, Formal, Translate, your modes, **Try it**, or an edit with Claude chosen and a key added | The recognized text, the mode's instructions, the spoken language, the target language when translating, and your API key |
| OpenAI API | Clean, Formal, Translate, your modes, **Try it**, or an edit with OpenAI chosen and a key added | The same, with your OpenAI API key |
| A local server you run | Clean, Formal, Translate, your modes, **Try it**, or an edit with Local server chosen; Settings › AI Models also asks it for its models, and **Detect** looks for one on four local ports | The same without a key, sent only to the address you set |

An edit also sends the selected text. Raw and Light never use the network. In
the AI modes, only the model you chose receives the text, never the audio.
Waft asks OpenAI not to store the response. Anthropic's
[privacy policy](https://www.anthropic.com/legal/privacy) and OpenAI's
[API data controls](https://developers.openai.com/api/docs/guides/your-data)
describe how each handles it.

## What Waft keeps

| What | Where |
| --- | --- |
| Settings | The `com.okoflow.waft` preferences domain |
| Dictionary and snippets | `~/Library/Application Support/Waft/dictionary.json` |
| Word and time counts per day for the statistics, no text | `~/Library/Application Support/Waft/stats.json` |
| History, kept for a month unless you choose otherwise | `~/Library/Application Support/Waft/history.json`, readable only by you |
| Speech model | `~/Library/Application Support/Waft/Models` |
| The model compiled for your chip | `~/Library/Caches/com.okoflow.waft` |
| Claude and OpenAI API keys | The login Keychain, service `com.okoflow.waft`, on this Mac only |
| Waft Pro license key | The login Keychain, service `com.okoflow.waft`, checked on your Mac without a server |

**Copy Last Dictation** keeps your last text in memory for 10 minutes; it is
never written to disk. With **Keep history** off, no new texts are added to the
history, and a text kept out of a password field is never saved.

## Logs

Waft writes to the unified log under the `com.okoflow.waft` subsystem: what it
did, how long it took, the mode, why an AI mode fell back to Light, the app it
pasted into, and how many characters it pasted. The dictated text and the
audio never reach the log.

## Removing everything

With Homebrew, `brew uninstall --zap --cask waft` removes the app and its data.
Otherwise, quit Waft, delete the app, and run:

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
`tccutil` removes the permissions you granted. Both are needed with Homebrew
too.

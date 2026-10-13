# Usage

Everything Waft can do and every setting. [Getting started](getting-started.md)
covers the first launch; [How it works](how-it-works.md) explains what
happens behind the scenes.

## Dictating

Hold the dictation key, speak, and let go. While you speak, the HUD at the
bottom of the screen shows a level meter; once the text is pasted, it shows
the text.

- A press shorter than 0.3 seconds does nothing, so a tap keeps the key's
  usual meaning.
- Pressing another key while you hold the dictation key cancels the
  recording, so Option shortcuts and special characters keep working.
- A recording stops on its own after 5 minutes.
- You can dictate again while the previous text is still being recognized.
  Texts arrive in the order you spoke them.

**Hands-free.** Tap the key twice quickly: Waft keeps listening without the
key held, shows **Hands-free** in the HUD, and finishes when you press the key
once more. Turn off **Double-tap for hands-free** in Settings › Dictation if
you don't want it.

**The dictation key** is <kbd>right ⌥</kbd>. To change it, click the key
next to **Dictation key** in Settings › Dictation and press another: Option,
Command, Shift, or Control on either side, Fn (🌐), or a function key. Keys
that type text can't be used.

## The menu

![The menu bar menu](../.github/screenshots/menu.jpg)

| Item | What it does |
| --- | --- |
| The first line | Says what Waft is doing: which key to hold, **Listening…**, the speech model's progress, or **Setup needed** |
| Finish Setup… | Appears while the setup guide is unfinished or a permission is missing, and opens the guide, or only its missing permission steps once setup is done |
| Retry Speech Model | Appears when the speech model failed, and downloads or loads it again |
| Install Update… | Appears when an update is waiting, and offers to install it |
| Mode | Sets the mode for every app; <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> switches to the next one |
| Mode in *app* | Gives the app in front a mode of its own |
| Language | Detects the language automatically, or uses the one you choose; **Choose Languages…** opens Settings › Dictation |
| Copy Last Dictation | Copies the latest text again for 10 minutes, even one that wasn't pasted |
| Recent Dictations | Copies one of your last five dictations; **Show History** opens the full list |
| Transcribe File… | Turns a recording or a video into text or subtitles |
| Settings… | Opens Settings |
| Unlock Waft Pro… | Appears once Pro is on sale and you have no license, and opens Settings › Waft Pro |
| Check for Updates… | Looks for a new version now |
| Quit Waft | Quits Waft |

To hide the icon, turn off **Show in menu bar** in Settings › General.
Dictation keeps working, <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> still switches
the mode, and opening Waft again brings up Settings.

## Modes

| Mode | What it does | Network |
| --- | --- | --- |
| Raw | Pastes exactly what Whisper heard | None |
| Light | Removes hesitations such as "um" or "ээ", tidies the spacing, capitalizes, and adds a period | None |
| Clean | Also removes filler words and false starts, keeps only your final version, and fixes grammar and punctuation | The text goes to the AI model |
| Formal | Like Clean, in a polite business tone | The text goes to the AI model |
| Translate | Translates what you said into another language | The text goes to the AI model |

Light is the default. It leaves words with meaning alone: filler words such as
"like" and self-corrections need Clean. Light also understands two voice
commands in 19 languages: say "new line" or "new paragraph" as a phrase of its
own, with a short pause before and after, and Waft starts a new line or
paragraph there.

Clean and Formal keep the language you spoke. Spoken punctuation such as
"comma" becomes the mark, dates, times, and amounts become digits, and items
you enumerate ("first…, second…") go on numbered lines. Formal keeps the way
you address the reader, such as *du* or *Sie*.

Translate uses the language from Settings › Writing › Translation, English
by default. Set **Two-way with** to a second language to translate both ways:
with English and Russian, what you say in English comes out in Russian and
what you say in Russian comes out in English.

When the AI model can't be used, Waft pastes the Light text instead and the
HUD says why: no API key, no network, an error, an unusable answer, or no
answer in time. [How it works](how-it-works.md#the-ai-modes) gives the time
limits, and [Troubleshooting](troubleshooting.md#the-ai-modes-use-light) each
reason.

### Choosing the AI model

Choose the **Provider** under **AI model** in Settings › AI Models, then set
it up in the section that appears below it.

- **Local server** calls a model you run yourself with Ollama, LM Studio,
  llama.cpp, MLX, or Jan. **Detect** finds a running server and fills in
  **Server address**, and **Model** lists the models it has loaded. Any
  server with an OpenAI-compatible `/v1/chat/completions` endpoint works, and
  the text never leaves your Mac.
- **Claude** needs an API key created inside a workspace in the
  [Anthropic Console](https://console.anthropic.com/settings/keys).
- **OpenAI** needs an API key from the
  [OpenAI dashboard](https://platform.openai.com/settings/organization/api-keys).

API keys are kept in your login Keychain on this Mac. **Remove** deletes them.

### Your own instructions

In Settings › Writing, **Instructions…** next to Clean, Formal, and Translate
shows what the mode asks the model to do and lets you rewrite it, for example
for a more casual tone or your team's style. Waft still tells the model to
treat what you said as text, not as a request, and to reply with the text
only. **Reset to Default** brings back the original.

### A mode for each app

An app can have a mode of its own, such as Formal in Mail and Raw in Terminal.
Choose **Mode in *app*** in the menu while the app is in front, or add the app
in Settings › Writing › Apps. Waft uses the mode of the app that was in front
when you pressed the key.

## Editing by voice

Set the **Editing key** under **Editing by voice** in Settings › Dictation.
Then select text in any app, hold that key, say what to change, such as "make
it shorter", "turn this into a list", or "translate into German", and let go.
The AI model rewrites the selection and Waft pastes the result over it.

What you say is an instruction, not text to paste, so nothing changes when the
model can't be reached: the HUD says why and the selection stays as it was.
An edit gets more time than a dictation, as
[How it works](how-it-works.md#editing-by-voice) explains. Apps that don't
expose the selection to Accessibility, such as some web views, show "Select
the text to edit" instead.

## Transcribing files

**Transcribe File…** in the menu opens a window for recordings you already
have: interviews, voice memos, meetings, or videos. Drop an audio or video
file on it or choose one. Whisper transcribes it on your Mac, in the language
it detects or the one you pick. Copy the text, save it as a text file, or
save SRT subtitles with timestamps. Dictation keeps working while a file is
in progress.

## Languages

![Settings with the languages](../.github/screenshots/languages.jpg)

Add the languages you speak in Settings › Dictation with **Add Language**, and
Waft detects which of them you speak each time. Fewer languages make detection
faster and more accurate. To skip detection, choose one language as the
**Spoken language** or in the **Language** menu. On first launch, Waft adds up
to three of your Mac's preferred languages and English.

Waft understands 45 languages: Arabic, Azerbaijani, Bosnian, Bulgarian,
Catalan, Chinese, Croatian, Czech, Danish, Dutch, English, Estonian, Filipino,
Finnish, French, Galician, German, Greek, Hebrew, Hindi, Hungarian, Indonesian,
Italian, Japanese, Korean, Latvian, Lithuanian, Macedonian, Malay, Norwegian,
Polish, Portuguese, Romanian, Russian, Serbian, Slovak, Slovenian, Spanish,
Swedish, Tamil, Thai, Turkish, Ukrainian, Urdu, and Vietnamese.

Languages that sound alike, such as Russian and Ukrainian, Danish and
Norwegian, Indonesian and Malay, or Serbian, Croatian, and Bosnian, get mixed
up when you enable them together. Settings › Dictation then suggests choosing
the one you speak as the **Spoken language**.

## Dictionary and snippets

Settings › Dictionary holds two lists.

**Terms** are names and words that come out wrong. Waft gives them to Whisper
as a hint, then replaces the spellings Whisper still writes, which you list
under **Heard as**, separated by commas. Replacements match whole words in any
letter case and work in every mode.

**Snippets** turn a phrase into text. Say the phrase on its own, and Waft
pastes the text exactly as written, without sending anything to an AI model.
The phrase inside a longer dictation is replaced too.

Both lists live in `dictionary.json`, which **Open in Editor** opens. Edits to
the file apply from the next dictation:

```json
{
  "terms": [
    { "term": "Kubernetes", "spoken": ["kubernetis", "kuber"] },
    { "term": "WhisperKit" }
  ],
  "snippets": [
    { "trigger": "my email", "text": "name@example.com" }
  ]
}
```

If the file can't be read, Waft keeps a copy as `dictionary.unreadable.json`
next to it before starting with an empty dictionary.

## Overview and history

Settings › Overview shows the last 7 days: how many words you dictated, the
time that saved over typing at 40 words a minute, and your speaking speed,
with a chart of the words for each day. Below that come your words and
dictations of all time and how many days in a row you have dictated. Only
these counts are kept, never the text; **Reset Statistics…** sets them back to
zero.

Settings › History lists your dictations with the time, the mode, and the app,
50 to a page, and copies any of them with one click; **Search** finds one by
its text. Dictations stay for a month and up to 1,000 of them unless you
change **Keep dictations for** or **Keep at most**. Turn off **Keep history**
to stop saving new ones; **Clear History…** deletes them all. A text kept out
of a password field is never saved.

## Settings

| Pane | What you set there |
| --- | --- |
| Overview | Statistics for the last 7 days and all time |
| General | Opening at login, the menu bar icon, the interface language, sounds, updates, permissions |
| Dictation | The dictation key, hands-free, the microphone, the editing key, languages |
| Writing | The mode and its instructions, translation, per-app modes, pasting |
| AI Models | The speech model, Fast or Accurate, the model for the AI modes, a local server, and Claude or OpenAI with your API keys |
| Dictionary | Terms and snippets |
| History | How long and how much to keep, searching, copying, and clearing |
| Waft Pro | What Pro adds and your license |
| About | The version, the website, the source code, and the license |

**App language** in Settings › General switches Waft's interface between
English, Chinese, French, German, Italian, Japanese, Korean, Portuguese,
Russian, Spanish, and Ukrainian, or follows macOS. Waft asks to relaunch to
apply it.

With **Paste into the focused field** off in Settings › Writing, Waft only
puts the text on the clipboard for you to paste with <kbd>⌘</kbd><kbd>V</kbd>.

## Updates

Waft checks for a new version once a day and asks before installing it; the
menu shows **Install Update…** when one is waiting. Turn off **Check for
updates automatically** in Settings › General to check only when you choose
**Check for Updates…**. Updates and the update feed are signed, and Waft
installs only an update signed with the project's key. A Homebrew installation
updates the same way.

## Waft Pro

Dictation with Whisper, the Raw and Light modes, voice commands, the
dictionary, and history are free. Waft Pro adds Clean, Formal, and Translate
with any AI model, translation both ways, your own instructions, editing by
voice, file transcription, and the Accurate speech model, for a single payment
of $13.99.

While Waft is in beta, every Pro feature is free and needs no license. Once
Pro goes on sale, it works for 3 days after the first launch; after that, the
AI modes fall back to Light, the HUD says so, and the menu marks them
**(Pro)** until you add a license in Settings › Waft Pro, and Waft recognizes
speech with the Fast model. The license key arrives with your receipt: paste
it under **License**, or open the activation link from the email. Waft checks
the key on your Mac, without contacting a server.

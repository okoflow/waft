# Usage

This page describes everything Waft does and every setting.
[Getting started](getting-started.md) covers the first launch, and
[How it works](how-it-works.md) what happens behind the scenes.

## Dictating

Hold the dictation key, speak, and let go. While you speak, the HUD beside
the notch, or at the top of a screen without one, shows how long you've
been speaking and a level meter. Once you let go, it shows that Waft is
transcribing, and while an AI mode cleans the text up, the mode's name and
what Whisper heard.
After pasting, it shows the text, up to three lines; click it to copy the
whole text again.

- A quick tap does nothing unless you choose **Tap**, so the key keeps its
  usual meaning.
- Pressing another key while you hold the dictation key cancels the
  recording, so shortcuts and special characters that use the key keep
  working.
- Press <kbd>Esc</kbd> to cancel a recording you started by mistake, held or
  hands-free: nothing is pasted. The key still reaches the app in front.
- A recording ends on its own after 5 minutes, and Waft pastes what you said.
- You can dictate again while the previous text is still being recognized;
  texts arrive in the order you spoke them.
- With **Paste into the focused field** off in Settings › Writing, Waft only
  copies the text, for you to paste with <kbd>⌘</kbd><kbd>V</kbd>.

### The dictation key

The dictation key is <kbd>right ⌥</kbd>. To change it, click the field next to
**Dictation key** in Settings › Dictation and press another: Option, Command,
Shift, or Control on either side, Fn (🌐), or a function key. Keys that type
text and the editing key can't be used. **How to start**, in the same pane,
sets what the key does:

- **Hold**: Waft listens while you hold the key.
- **Tap**: tap the key to start and tap it again to finish.
- **Hold or double-tap**, the default: hold the key, or tap it twice to start
  and once more to finish.

While Waft listens without the key held, the HUD shows a lock instead of
the microphone.

### The speech model

**Speech model** in Settings › Dictation offers Fast, the default, and
Accurate (Waft+). [The speech model](how-it-works.md#the-speech-model) compares
the two.

## Languages

![Settings with the languages](../.github/screenshots/languages.jpg)

Add the languages you speak with **Add Language** in Settings › Dictation, and
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

Chinese and Serbian each have a **Writing system** next to them in Settings ›
Dictation: Simplified or Traditional characters, and Latin or Cyrillic
letters. Waft writes dictations, AI answers, and transcribed files in the one
you choose.

## Modes

| Mode | What it does | Needs the AI model |
| --- | --- | --- |
| Raw | Pastes exactly what Whisper heard | No |
| Light | Removes hesitations such as "um" or "ээ", tidies the spacing, capitalizes, and adds a period | No |
| Clean | Also removes filler words and false starts, keeps only your final version, and fixes grammar and punctuation | Yes |
| Formal | Like Clean, in a polite business tone | Yes |
| Translate | Translates what you said into another language | Yes |
| Your modes | Follow the instructions you wrote | Yes |

Light is the default mode; choose another under **Mode** in the menu or in
Settings › Writing. Light leaves words with meaning alone: filler words such as
"like" and self-corrections need Clean. It also understands two voice commands
in 19 languages: say "new line" or "new paragraph" as a phrase of its own, with
a short pause before and after, and Waft starts a new line or paragraph there.

Clean and Formal keep the language you spoke. Spoken punctuation such as
"comma" becomes the mark, dates, times, and amounts become digits, and items
you enumerate ("first…, second…") go on numbered lines. Formal keeps the way
you address the reader, such as *du* or *Sie*.

Translate writes in the language set under **Translate into** in Settings ›
Writing, English by default. Set **Two-way with** to a second language to
translate both ways: with English and Russian, what you say in English comes
out in Russian and what you say in Russian comes out in English.

When the AI model can't be used, Waft pastes the Light text instead and the
HUD says why.
[The AI modes use Light](troubleshooting.md#the-ai-modes-use-light) lists the
reasons and what to do about each.

### Choosing the AI model

Choose the **Provider** in Settings › AI Models, Claude by default, then set it
up in the section that appears below it.

- **Local server** calls a model you run yourself with Ollama, LM Studio,
  llama.cpp, MLX, or Jan. **Detect** finds a running server, fills in
  **Server address**, and picks one of its models under **Model**. Any server
  with an OpenAI-compatible `/v1/chat/completions` endpoint works. With a server
  on your Mac the text never leaves it; with an address elsewhere it goes only
  to that server, and Settings says so.
- **Claude** needs an API key created inside a workspace in the
  [Anthropic Console](https://console.anthropic.com/settings/keys).
- **OpenAI** needs an API key from the
  [OpenAI dashboard](https://platform.openai.com/settings/organization/api-keys).

For Claude or OpenAI, paste the key under **API key** and click **Save**;
**Remove** deletes it. **Model** offers three models:

| Trade-off | Claude | OpenAI |
| --- | --- | --- |
| The quickest and cheapest | Haiku 5.5 | GPT-6 Luna |
| Fewer mistakes, still quick; the default | Sonnet 5.5 | GPT-6.1 Sol |
| The fewest mistakes, slower and pricier | Opus 5.5 | GPT-6 Astra |

### Your modes

In Settings › Writing, the arrow next to Clean, Formal, or Translate opens the
mode's page, where you can rewrite its **Instructions**, for example for a
more casual tone or your team's style. **Reset to Default** brings back the
original.

**New Mode** under **Your modes** adds a mode: give it a name and
instructions, such as "reply as a short, friendly email and sign with my name"
or "turn what I say into bullet points". Where the instructions say nothing,
Waft removes hesitations, fixes grammar and punctuation, and keeps your
language. Your modes appear in the menu, in the modes for each app, and in the
<kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> cycle. **Delete Mode…** removes one: apps
that used it switch to the default mode, and if it was the default, Waft uses
Light.

Each mode's page has **Try it**: type a sentence under **You say** and click
**Run** to see what the mode writes with your AI model. The test skips the
dictionary and assumes the first of your languages.

### A mode for each app

An app can have a mode of its own, such as Formal in Mail and Raw in Terminal.
Choose **Mode in *app*** in the menu while the app is in front, or click
**Add App…** in Settings › Writing › Apps. Waft uses the mode of the app that
was in front when you pressed the key.

## Editing by voice

Set the **Editing key** in Settings › Dictation; there's none by default, and
it always works by holding. Then select text in any app, hold that key, say
what to change, such as "make it shorter", "turn this into a list", or
"translate into German", and let go. The AI model rewrites the selection and
Waft pastes the result over it.

What you say is an instruction, not text to paste, so a failed edit changes
nothing; [The text isn't pasted](troubleshooting.md#the-text-isnt-pasted)
lists what the HUD says then.

## Transcribing files

**Transcribe File…** in the menu opens a window for recordings you already
have: interviews, voice memos, meetings, or videos. Drop an audio or video
file on it or click **Choose File…**. Whisper transcribes it on your Mac, in
the language it detects or the one you choose under **Language**; no mode or
dictionary applies. Copy the text, or click **Save Text…** or
**Save Subtitles…** for SRT subtitles with timestamps. Dictation keeps working
while a file is in progress.

## Dictionary and snippets

Settings › Dictionary holds two lists.

**Terms** are names and words that come out wrong. Waft gives them to Whisper
as a hint, then replaces the spellings Whisper still writes, which you list
under **Heard as**, separated by commas. Replacements match whole words in any
letter case and work in every mode.

**Snippets** turn a phrase into text. Say the phrase on its own, and Waft
pastes the text exactly as written, without sending anything to an AI model.
The phrase inside a longer dictation is replaced too.

Both lists live in `dictionary.json`, which **Open in Editor** opens:

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

Edits to the file apply from the next dictation.

## Overview and history

Settings › Overview shows the last 7 days: how many words you dictated, the
time saved over typing at 40 words a minute, and your speaking speed, with a
chart of the words for each day. Below that come your words and dictations of
all time and how many days in a row you have dictated. **Reset Statistics…**
sets the counts back to zero.

Settings › History lists your dictations with the time, the mode, and the app,
50 to a page, and copies any of them with one click; **Search** finds one by
its text. Dictations stay for a month and up to 1,000 of them unless you
change **Keep dictations for** or **Keep at most**. Turn off **Keep history**
to stop saving new ones; **Clear History…** deletes them all.

## The menu

![The menu bar menu](../.github/screenshots/menu.jpg)

| Item | What it does |
| --- | --- |
| The first line | Says what Waft is doing: which key to hold or tap, "Listening…", the speech model's progress, "Speech model failed", or "Setup needed" |
| Finish Setup… | Appears while setup is unfinished or a permission is missing, and opens the steps that remain |
| Retry Speech Model | Appears when the speech model failed, and downloads or loads it again |
| Install Update… | Appears when an update is waiting, and offers to install it |
| Mode | Sets the default mode, which every app without its own mode uses; <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> switches to the next one |
| Mode in *app* | Gives the app in front a mode of its own |
| Language | Detects the language automatically, or uses the one you choose; **Choose Languages…** opens Settings › Dictation |
| Copy Last Dictation | Copies the latest text, pasted or not, within 10 minutes of the dictation |
| Recent Dictations | Copies one of your last five dictations from the history; **Show History** opens the full list |
| Transcribe File… | Turns a recording or a video into text or subtitles; marked "(Waft+)" without Waft+ |
| Settings… | Opens Settings |
| Unlock Waft+… | Appears once Waft+ is on sale and you have no license, and opens Settings › Waft+ |
| Check for Updates… | Looks for a new version now |
| Quit Waft | Quits Waft |

To hide the icon, turn off **Show in menu bar** in Settings › General.
Dictation keeps working, <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> still switches
the mode, and opening Waft again brings up Settings.

## Settings

The sidebar follows a dictation from your voice to the text: Overview first,
then **Voice** with Dictation and Dictionary, **Text** with Writing and AI
Models, **App** with History and General, and Waft+ and About at the bottom.

| Pane | What you set there |
| --- | --- |
| Overview | Statistics for the last 7 days and all time |
| Dictation | How to start, the dictation key, the microphone, the speech model, the editing key, and the languages |
| Dictionary | Terms and snippets |
| Writing | The modes and their instructions, your modes, translation, per-app modes, and pasting |
| AI Models | The provider for the AI modes, a local server, and Claude or OpenAI with your API keys and models |
| History | How long and how much to keep, searching, copying, and clearing |
| General | Opening at login, the menu bar icon, the interface language, sounds and lowering other sounds while recording, updates, and permissions |
| Waft+ | What Waft+ adds and your license |
| About | The version, the website, the source code, and the license |

**App language** in Settings › General switches Waft's interface between 23
languages, or **Same as macOS**: English, Arabic, Chinese (Simplified and
Traditional), Danish, Dutch, French, German, Hebrew, Italian, Japanese,
Korean, Norwegian, Polish, Portuguese (Brazil and Portugal), Russian, Spanish
(Spain and Latin America), Swedish, Thai, Turkish, and Ukrainian. Arabic and
Hebrew lay the interface out from right to left. Click **Relaunch** to apply
it.

**Lower other sounds while recording**, in the same pane and on by default,
turns the Mac's volume down to a quarter once recording starts, after the start
click, and brings it back when recording ends. If you change the volume while
you speak, Waft leaves your choice alone.

## Updates

Waft checks for a new version once a day and asks before installing it. Turn
off **Check for updates automatically** in Settings › General to check only
when you click **Check Now** there or choose **Check for Updates…** in the
menu. Waft installs only an update signed with the project's key. A debug
build, such as one from `make run`, doesn't update itself: pull and build
again, as [Development setup](../CONTRIBUTING.md#development-setup) describes.

## Waft+

Dictation with Whisper, the Raw and Light modes, voice commands, the
dictionary, and history are free. Waft+ adds Clean, Formal, Translate,
your modes, rewritten instructions, editing by voice, file transcription, and
the Accurate speech model for a single payment of $13.99. Settings marks each
of them with the Waft+ mark, a "+" in a dark circle.

While Waft is in beta, every Waft+ feature is free and needs no license. Once
Waft+ goes on sale, a trial unlocks it for 3 calendar days, starting on the day
you first open a version that sells it. After the trial, until you add a
license in Settings › Waft+:

- The AI modes fall back to Light, and the HUD says so.
- The editing key records nothing, and the HUD says it needs Waft+.
- The menu marks the AI modes and file transcription "(Waft+)".
- <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> switches only between Raw and Light.
- Waft recognizes speech with the Fast model.

The license key arrives with your receipt: paste it into **License key** and
click **Activate**, or open the activation link in the email. Waft checks the
key on your Mac, without contacting a server. **Remove License…** takes it off
this Mac.

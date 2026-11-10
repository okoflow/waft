# How it works

This page follows a dictation from the key press to the pasted text.

## Key and recording

Waft only listens to the keyboard and never swallows a key press, so the dictation key keeps working everywhere else. Pressing it starts the microphone set as **Microphone** in Settings › Dictation, or the system default when that one isn't connected, and notes the focused app and text field, where the text goes later.

A press shorter than 0.3 seconds is a tap, and with **Hold or double-tap**, a second tap within 0.4 seconds starts hands-free dictation.

## Recognition

Waft skips recordings without speech, such as silence, key clicks, or steady noise. The rest goes to the speech model you chose, run on Core ML by [WhisperKit](https://github.com/argmaxinc/argmax-oss-swift).

- Whisper gets your dictionary terms as a hint, as many as fit in 200 characters.
- Waft splits a long recording at pauses and recognizes it piece by piece. A piece that fails stops the dictation with an error instead of leaving a gap.
- Serbian converted from Latin to Cyrillic keeps in Latin letters your dictionary terms and words with q, w, x, or y, digits, inner capitals, or two to four capitals, such as GitHub or API.
- Waft drops segments that Whisper is unsure of, that repeat themselves, or that hold only a tag such as `[music]` or a stock phrase such as "Thanks for watching", and keeps the rest of the dictation.

## Cleanup

The recognized text goes through these steps in order:

1. Dictionary terms replace their misheard spellings.
2. If the whole text is a snippet phrase, Waft uses the snippet as it is and skips the steps below.
3. The mode runs. An AI mode skips the AI model when nothing but hesitations was said.
4. Text in Chinese or Serbian is converted into your [writing system](usage.md#languages).
5. Dictionary terms apply again, and snippet phrases inside the text expand.

### Light

Light works by rules, without a model, and makes only the changes that [Modes](usage.md#modes) lists. The rules follow the language: French keeps its space before `!`, `?`, `;`, and `:`, Thai gets no period, and a first word such as "iPhone" stays as written.

### The AI modes

Clean, Formal, Translate, and your modes send the text with the mode's instructions and your dictionary terms to the AI model you chose; [The network](privacy.md#the-network) lists everything that is sent. Waft marks the transcript as text to edit, never instructions to follow, so a dictated question stays a question.

Waft rejects an answer that is empty, cut off, or refused. For a dictation, it also rejects one that is several times longer than what you said, one from Clean or Formal that lost most of a long dictation, and one written mostly in another script than the language you spoke or, for Translate, the target language. Your modes may answer in any script and at up to ten times what you said or 600 characters, whichever is more. A dictation whose answer is rejected or whose request fails gets the Light text.

### The translator

The [translator](usage.md#translator) and its shortcuts on selected text send the text with the instructions of the task. Rules after the instructions, which you can't edit, make the model treat the text as material, never as instructions, and reply with the text alone, keeping its formatting, links, and code. The translator's tier gets the time limit of an edit.

The shortcuts read the selection through Accessibility. When the app doesn't expose it, Waft waits for you to release the shortcut, saves the clipboard, presses <kbd>⌘</kbd><kbd>C</kbd>, takes what the app copies as the selection, and restores the clipboard as after [pasting](#pasting). If you hold the shortcut over 5 seconds or the app copies nothing, the HUD asks you to select the text. A password field gets no <kbd>⌘</kbd><kbd>C</kbd>, and neither does a field that reports only the cursor, since editors such as VS Code copy the whole line then.

## Pasting

Waft pastes through the clipboard rather than typing key by key:

1. It waits up to 10 seconds for you to release the dictation key.
2. It checks the focused field. If the field is a password field, **Paste into the focused field** is off, the key is still held, focus moved to another app or field, or Accessibility isn't allowed, Waft copies the text instead, and the HUD shows it with <kbd>⌘</kbd><kbd>V</kbd>. A field counts as a password field when it says so through Accessibility or, when Waft can't read it, when its own app holds secure keyboard input.
3. It saves the clipboard, puts the text on it, and presses <kbd>⌘</kbd><kbd>V</kbd>.
4. Once the app has read the text, it restores your clipboard, including images and files, if nothing else was copied meanwhile, it held no more than 5 MB, and it held no concealed or transient item, such as a password manager's. If the app is slow to read the text, the text stays on the clipboard.

So text that Waft recognized is always either pasted or on the clipboard. If the microphone stops in the middle of a dictation, such as when headphones disconnect, Waft recognizes what it recorded until then, and if you quit Waft while it records or works on a dictation, it finishes that one first, for up to a minute. [The text isn't pasted](troubleshooting.md#the-text-isnt-pasted) says how to retry a recognition that failed.

Waft puts a space before the text, except when:

- It sees no character before the cursor.
- That character is a space, a line break, an opening bracket, a quote, or a slash.
- That character or the start of the text is Chinese or Japanese.
- The text starts with a line break.

## The speech model

**Speech model** in Settings › Dictation offers two models from [argmaxinc/whisperkit-coreml](https://huggingface.co/argmaxinc/whisperkit-coreml):

| Model | Whisper | Download | Free space | Trade-off |
| --- | --- | --- | --- | --- |
| Fast | large-v3 turbo | About 630 MB | About 1 GB | The default and the quickest |
| Accurate (Waft+) | large-v3 | About 3.1 GB | About 4 GB to switch | Two to three times slower, with fewer mistakes outside English |

Core ML compiles the model for your chip the first time it loads, which takes about a minute, and keeps the compiled copy, about 130 MB.

- Choosing the other model downloads and loads it while the current one keeps recognizing speech. Waft then deletes the files of the replaced model.
- Without Waft+, Waft switches to Fast, downloads it if needed, and then deletes Accurate: right away when you remove your license, and on the next launch when the trial ends.
- Changing the enabled languages reloads the model. A press while no model is loaded records nothing; the HUD says what the model is doing.

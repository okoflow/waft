<p align="center">
  <img
    src="Packaging/Waft.png"
    width="128"
    alt=""
  >
</p>

<h1 align="center">Waft</h1>

<p align="center">On-device dictation for macOS with AI cleanup.</p>

<p align="center">
  <a
    href="https://github.com/okoflow/waft/actions/workflows/ci.yml"
  ><img
    src="https://github.com/okoflow/waft/actions/workflows/ci.yml/badge.svg"
    alt="CI"
  ></a>
  <a
    href="LICENSE"
  ><img
    src="https://img.shields.io/badge/license-GPL--3.0--only-blue"
    alt="License: GPL-3.0-only"
  ></a>
  <img
    src="https://img.shields.io/badge/macOS-14%2B-informational"
    alt="macOS 14 or later"
  >
</p>

<p align="center">
  <a href="https://waft.okoflow.com">Website</a> ·
  <a href="#install">Install</a> ·
  <a href="docs/getting-started.md">Getting started</a> ·
  <a href="docs/usage.md">Usage</a> ·
  <a href="docs/privacy.md">Privacy</a>
</p>

https://github.com/user-attachments/assets/a6d44cd4-8c34-40dc-84f6-095fab844ae6

**Hold <kbd>right ⌥</kbd>, speak, let go.** The text appears wherever you are
typing, in any app. Speech is recognized on your Mac; an AI mode cleans it up
when you want prose rather than a transcript.

<table>
  <thead>
    <tr>
      <td
        width="33%"
        valign="top"
      ><b>Private</b><br>Whisper runs on your Mac through WhisperKit. Audio is
        never saved or sent.</td>
      <td
        width="33%"
        valign="top"
      ><b>45 languages</b><br>Waft detects which of your languages you speak,
        and translates between them.</td>
      <td
        width="33%"
        valign="top"
      ><b>AI cleanup</b><br>Clean, Formal, Translate, or your modes, with
        Claude, OpenAI, or a local server.</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td valign="top"><b>Edit by voice</b><br>Select text, hold a key, and say
        "make it shorter".</td>
      <td valign="top"><b>Transcribe files</b><br>Recordings and videos to text
        or SRT subtitles.</td>
      <td valign="top"><b>Your words</b><br>A dictionary for names, snippets for
        phrases, history on your Mac.</td>
    </tr>
  </tbody>
</table>

![The HUD while listening, transcribing, and after pasting](.github/screenshots/hud.jpg)

## How it compares

<picture>
  <source
    media="(prefers-color-scheme: dark)"
    srcset=".github/screenshots/comparison-dark.jpg"
  >
  <img
    src=".github/screenshots/comparison-light.jpg"
    alt="Waft compared with Wispr Flow, Superwhisper, MacWhisper, VoiceInk,
    Aqua Voice, and Apple Dictation"
  >
</picture>

## Install

Waft runs on a Mac with Apple silicon and macOS 14 or later.
[Getting started](docs/getting-started.md) walks you from building it to your
first dictation.

## Documentation

| Guide | What it covers |
| --- | --- |
| [Getting started](docs/getting-started.md) | Installing, the permissions, and your first dictation |
| [Usage](docs/usage.md) | Modes, languages, editing by voice, files, the dictionary, history, and every setting |
| [How it works](docs/how-it-works.md) | What happens between the key and the pasted text |
| [Privacy](docs/privacy.md) | What stays on your Mac, what leaves it, and how to remove everything |
| [Troubleshooting](docs/troubleshooting.md) | What to do when something doesn't work, and what the menu and the HUD tell you |
| [Architecture](docs/architecture.md) | How the code is organized, for contributors |

## Waft Pro

Waft Pro adds the AI modes, editing by voice, file transcription, and the
Accurate speech model for a single payment of $13.99. **Free while Waft is in
beta.** [Waft Pro](docs/usage.md#waft-pro) covers the details.

## Contributing

Pull requests are welcome. [CONTRIBUTING.md](CONTRIBUTING.md) covers the
setup, the checks CI runs, and the conventions. Report vulnerabilities
privately as described in [SECURITY.md](SECURITY.md).

## License

Waft is copyright The Waft Authors, listed in [AUTHORS](AUTHORS), and licensed
under GPL-3.0-only, whose text is in [LICENSE](LICENSE). Releases up to 0.3.0
were MIT; [NOTICE](NOTICE) keeps those terms. The license covers the code, not
the Waft name and logo.

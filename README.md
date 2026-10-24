<p align="center">
  <img
    src="Packaging/Waft.png"
    width="128"
    alt=""
  >
</p>

<h1 align="center">Waft</h1>

<p align="center">On-device dictation with AI cleanup.</p>

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
  <a href="docs/getting-started.md#1-install">Install</a> ·
  <a href="docs/usage.md">Usage</a> ·
  <a href="docs/privacy.md">Privacy</a>
</p>

https://github.com/user-attachments/assets/359db10e-c56e-4ece-ab27-7a31721d0264

**Hold <kbd>right ⌥</kbd>, speak, let go.** The text appears wherever you type, in any app. Whisper recognizes your speech on your Mac, and an AI mode cleans it up when you want prose.

<table>
  <thead>
    <tr>
      <td
        width="33%"
        valign="top"
      ><b>Private</b><br>Whisper runs on your Mac. Audio is never saved or
        sent.</td>
      <td
        width="33%"
        valign="top"
      ><b>45 languages</b><br>Waft detects which of your languages you
        speak, and translates.</td>
      <td
        width="33%"
        valign="top"
      ><b>AI cleanup</b><br>Clean, Formal, Translate, or your modes, with
        Claude, OpenAI, or a local model.</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td valign="top"><b>Edit and translate</b><br>Say "make it shorter" over
        a selection, or translate it with a shortcut.</td>
      <td valign="top"><b>Transcribe files</b><br>Recordings and videos to
        text or SRT.</td>
      <td valign="top"><b>Your words</b><br>A dictionary, snippets, and history
        on your Mac.</td>
    </tr>
  </tbody>
</table>

![The HUD at the notch while listening, cleaning up, after pasting, and under the pointer](.github/screenshots/hud.jpg)

## Install

```sh
brew install --cask okoflow/tap/waft
```

Or download the disk image from the [latest release](https://github.com/okoflow/waft/releases/latest). [Install](docs/getting-started.md#1-install) lists the requirements and how to open a copy from the disk image the first time.

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

## Documentation

| Guide | What it covers |
| --- | --- |
| [Getting started](docs/getting-started.md) | Install and first dictation |
| [Usage](docs/usage.md) | Every feature and setting |
| [How it works](docs/how-it-works.md) | From key press to pasted text |
| [Privacy](docs/privacy.md) | What Waft keeps and sends |
| [Troubleshooting](docs/troubleshooting.md) | When something doesn't work |
| [Architecture](docs/architecture.md) | The code, for contributors |

## Waft+

Dictation is free. [Waft+](docs/usage.md#waft) adds the AI features and the Accurate speech model for a single payment of $13.99, and is free while Waft is in beta.

## Contributing

Pull requests are welcome; [CONTRIBUTING.md](CONTRIBUTING.md) covers the setup, checks, and conventions. Report vulnerabilities privately as [SECURITY.md](SECURITY.md) describes.

## License

Waft is copyright The Waft Authors ([AUTHORS](AUTHORS)) and licensed under GPL-3.0-only ([LICENSE](LICENSE)). The license covers the code, not the Waft name and logo.

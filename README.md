<p align="center">
  <img src="Packaging/Waft.png" width="128" alt="">
</p>

<h1 align="center">Waft</h1>

<p align="center">On-device dictation for macOS with AI cleanup.</p>

<p align="center">
  <a href="https://github.com/okoflow/waft/actions/workflows/ci.yml"><img src="https://github.com/okoflow/waft/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue" alt="License: GPL-3.0"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-informational" alt="macOS 14 or later">
</p>

<p align="center">
  <a href="https://waft.okoflow.com">Website</a> ·
  <a href="#install">Install</a> ·
  <a href="docs/usage.md">Usage</a> ·
  <a href="docs/privacy.md">Privacy</a>
</p>

https://github.com/user-attachments/assets/a6d44cd4-8c34-40dc-84f6-095fab844ae6

**Hold right Option, speak, let go.** The text appears wherever you are
typing, in any app. Speech is recognized on your Mac; an AI mode can
polish it when you want prose rather than a transcript.

<table>
  <thead>
    <tr>
      <td width="33%" valign="top"><b>Private</b><br>Whisper runs on your Mac through WhisperKit. Audio is never saved or sent.</td>
      <td width="33%" valign="top"><b>45 languages</b><br>Waft detects which of your languages you speak, and translates between them.</td>
      <td width="33%" valign="top"><b>AI cleanup</b><br>Clean, Formal, or Translate with Claude, OpenAI, or a local model.</td>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td valign="top"><b>Edit by voice</b><br>Select text, hold a key, and say "make it shorter".</td>
      <td valign="top"><b>Transcribe files</b><br>Recordings and videos to text or SRT subtitles.</td>
      <td valign="top"><b>Your words</b><br>A dictionary for names, snippets for phrases, history on your Mac.</td>
    </tr>
  </tbody>
</table>

![The HUD while listening, transcribing, and after pasting](.github/screenshots/hud.jpg)

## How it compares

<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/screenshots/comparison-dark.jpg">
  <img src=".github/screenshots/comparison-light.jpg" alt="Waft compared with Wispr Flow, Superwhisper, MacWhisper, VoiceInk, Aqua Voice, and Apple Dictation">
</picture>

## Install

Waft is built from source for now. You need a Mac with Apple silicon,
macOS 14 or later, and the Command Line Tools for Xcode 26.

```sh
git clone https://github.com/okoflow/waft.git
cd waft
make signing   # once: a local signing identity, so permissions survive rebuilds
make run       # builds, signs, and opens build/Waft.app
```

On first launch, a short guide asks for the microphone and Accessibility
and downloads the speech model (about 630 MB).

## Usage

1. Click into a text field.
2. Hold <kbd>right ⌥</kbd> and speak.
3. Let go.

Double-tap <kbd>right ⌥</kbd> to dictate hands-free, and press
<kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> to switch the mode: Raw, Light, Clean,
Formal, or Translate. Raw and Light work offline; the others send text, never
audio, to the model you choose. Everything else is in [Usage](docs/usage.md).

## Waft Pro

AI modes, translation, editing by voice, and file transcription cost $13.99
once. **Free while Waft is in beta.**

## Contributing

Pull requests are welcome. [CONTRIBUTING.md](CONTRIBUTING.md) covers the
setup, the checks CI runs, and the commit conventions. Report
vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## License

[GPL-3.0](LICENSE), copyright [The Waft Authors](AUTHORS). Releases up to
0.3.0 were MIT; [NOTICE](NOTICE) keeps those terms. The license covers the
code, not the Waft name and logo.

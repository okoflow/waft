# Getting started

This guide takes you from installing Waft to your first dictation.
[Usage](usage.md) covers everything after that, and
[Troubleshooting](troubleshooting.md) helps when something doesn't work.

## 1. Install

Waft runs on a Mac with Apple silicon and macOS 14 or later. Homebrew and a
disk image come with the first notarized release. Until then, build Waft from
source as [Development setup](../CONTRIBUTING.md#development-setup) describes;
`make run` opens it when the build is done. Waft lives in the menu bar, not
the Dock.

## 2. Follow the setup guide

On first launch, a short guide opens. While you go through it, Waft
downloads the speech model in the background, about 630 MB.

![The setup guide](../.github/screenshots/onboarding.jpg)

1. **Welcome to Waft** shows the gesture: hold the key, speak, let go.
2. **Allow microphone access**: click **Allow Access…** and allow the
   microphone. Waft records only while you dictate, and the audio stays on
   your Mac.
3. **Allow Accessibility access**: click **Open System Settings** and turn on
   Waft. Accessibility lets Waft notice the key and paste the text.
4. **Try it**: click the box, hold <kbd>right ⌥</kbd>, and say "Hello, Waft".
   While the model is still downloading, the line under the box says how far
   along it is.
5. **You're all set**: choose whether Waft opens at login, then click
   **Done**. Without an AI model, **Set Up…** next to **AI modes** opens
   Settings › AI Models.

The guide moves on by itself once a permission is allowed, and skips a
permission you allowed before. If you close it early, **Finish Setup…** in the
menu brings it back.

## 3. Dictate anywhere

1. Click into any text field: a message, a document, a prompt for an AI.
2. Hold <kbd>right ⌥</kbd> and speak. The HUD at the bottom of the screen
   shows that Waft is listening.
3. Let go. The text appears at the cursor.

A quick tap does nothing, so Option keeps working as usual. If the first word
goes missing, see [Limits](how-it-works.md#limits).

## 4. Try the rest

- **Hands-free**: tap <kbd>right ⌥</kbd> twice, speak as long as you like, and
  tap it again to finish. To start with a single tap, choose **Tap** under
  **How to start** in Settings › Dictation.
- **Modes**: press <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> to switch between Raw,
  Light, Clean, Formal, Translate, and the modes you make in Settings ›
  Writing. Every mode but Raw and Light needs an AI model: add an API key or a
  local server in Settings › AI Models.
- **Languages**: add the languages you speak in Settings › Dictation.

[Usage](usage.md) describes every feature and setting.

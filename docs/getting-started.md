# Getting started

This page takes you from installing Waft to your first dictation.
[Usage](usage.md) covers everything after that, and
[Troubleshooting](troubleshooting.md) helps when something doesn't work.

## 1. Install

Waft runs on a Mac with Apple silicon and macOS 14 or later, and needs about
1 GB of free space for the speech model, or 4 GB to switch to the Accurate
one. Until the first notarized release brings Homebrew and a disk image, build
Waft from source as [Development setup](../CONTRIBUTING.md#development-setup)
describes; building needs a newer macOS than running it. Waft lives in the
menu bar and shows in the Dock only while one of its windows is open.

## 2. Follow the setup guide

On first launch, a short guide opens. While you go through it, Waft downloads
the speech model in the background.

![The setup guide](../.github/screenshots/onboarding.jpg)

1. **Welcome to Waft** shows the gesture: hold the key, speak, let go.
2. **Allow microphone access**: click **Allow Access…**, then **Allow** in the
   macOS prompt.
3. **Allow Accessibility access**: click **Open System Settings** and turn on
   Waft. Accessibility lets Waft notice the key and paste the text.
4. **Try it**: click the box, hold <kbd>right ⌥</kbd>, and say "Hello, Waft".
   While the speech model is still downloading, the line under the box shows
   its progress.
5. **You're all set**: choose whether Waft opens at login, then click
   **Done**. If no AI model is set up, **Set Up…** next to **AI modes** opens
   Settings › AI Models.

The guide moves on by itself once a permission is allowed, and skips a
permission you allowed before. If you close it early, **Finish Setup…** in the
menu brings it back.

## 3. Dictate anywhere

1. Click into any text field: a message, a document, a prompt for an AI.
2. Hold <kbd>right ⌥</kbd> and speak. The HUD at the bottom of the screen
   shows that Waft is listening.
3. Let go. The text appears at the cursor.

If the first word goes missing, [Limits](how-it-works.md#limits) explains why.

## 4. Try the rest

- **Hands-free**: tap <kbd>right ⌥</kbd> twice, speak, and tap it once more to
  finish. [The dictation key](usage.md#the-dictation-key) lists the other ways
  to start.
- **Modes**: press <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> to switch between Raw,
  Light, Clean, Formal, Translate, and your modes. [Modes](usage.md#modes)
  says which need an AI model.
- **Languages**: add the languages you speak in Settings › Dictation, as
  [Languages](usage.md#languages) describes.

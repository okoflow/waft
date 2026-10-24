# Releasing

This page describes how you turn `main` into a release that users get from GitHub Releases, Homebrew, and in-app updates. [Checks](../CONTRIBUTING.md#checks) lists what every change passes before it reaches `main`.

## What a release is made of

| Artifact | Made by | Used by |
| --- | --- | --- |
| `Waft-X.Y.Z.dmg` | `scripts/release.sh`: the Waft Release signature | GitHub Releases, the Homebrew cask, and Sparkle |
| `appcast.xml` | Sparkle's `generate_appcast`, signed with the project's EdDSA key | Waft's updater, at `releases/latest/download/appcast.xml`, and the cask's `livecheck` |
| `waft.rb` | `scripts/release.sh`, from `Packaging/Homebrew/waft.rb` | `Casks/waft.rb` in `okoflow/homebrew-tap` |

Waft is not sandboxed, so the bundle ships Sparkle without its XPC services.

Until the project has a Developer ID, releases are signed with Waft Release, a self-signed identity. macOS ties the permissions it grants to that certificate, so they survive updates, but Gatekeeper blocks the first launch until the user clicks **Open Anyway**. The cask's `postflight_steps` remove the quarantine flag, so a copy from Homebrew opens right away. [Switching to a Developer ID](#switching-to-a-developer-id) lists what changes then.

## One-time setup

1. Create the Waft Release identity in the login keychain; it asks for your password to trust it:

   ```sh
   scripts/signing.sh 'Waft Release'
   ```

   Back it up with **Export** in Keychain Access and keep the file offline. Every release must use this certificate: a new one makes macOS forget the permissions of everyone who updates. On another Mac, import the backup instead of creating a new identity.
2. Import the Sparkle signing key into the login keychain from its offline backup with `generate_keys -f <file>`. `generate_keys -p` must then print the `SUPublicEDKey` of `Packaging/Waft-Info.plist`:

   ```sh
   swift package resolve
   .build/artifacts/sparkle/Sparkle/bin/generate_keys -p
   ```

   Make the backup with `generate_keys -x <file>` and keep it offline, since installed copies verify the feed with this key.

## Cutting a release

1. Merge a pull request titled `chore(release): prepare X.Y.Z` from the branch `release/X.Y.Z`. Its one commit, `chore(release): bump version to X.Y.Z`, sets `CFBundleShortVersionString` to `X.Y.Z` and raises `CFBundleVersion` by one in `Packaging/Waft-Info.plist`. Sparkle compares `CFBundleVersion`, so it must always grow.
2. Write the release notes outside the repository, since the script needs a clean working tree. Each section lists its changes; leave out an empty one. The contributors are the release's commit authors.

   ```md
   One summary sentence.

   ## Added

   ## Changed

   ## Fixed

   **Contributors**: @handle, @handle

   **Full changelog**: https://github.com/okoflow/waft/compare/vPREVIOUS...vX.Y.Z
   ```

3. Build, sign, and package `main`:

   ```sh
   SIGNING_IDENTITY='Waft Release' make release NOTES=../notes.md
   ```

   The script stops unless the working tree is clean, `HEAD` is `origin/main`, the version's tag isn't on `origin` yet, and [One-time setup](#one-time-setup) is done. It writes the disk image, the appcast with the notes embedded, and the cask with the disk image's checksum into `build/release`.

   Don't edit `appcast.xml`, since its signature covers the notes. To change it, rerun `generate_appcast` with the arguments of `make_appcast` in `scripts/release.sh`.
4. Publish the release with the command the script prints, which tags the commit it built. Releases are immutable: the tag, the files, and the notes embedded in the appcast can't change after publishing, so check them first. Mount the disk image and run `codesign --verify --strict` on the app in it.

   ```sh
   gh release create vX.Y.Z build/release/Waft-X.Y.Z.dmg build/release/appcast.xml \
     --target <commit> --title vX.Y.Z --notes-file ../notes.md
   ```

5. Copy `build/release/waft.rb` to `Casks/waft.rb` in your clone of `okoflow/homebrew-tap`, then commit and push it.

Installed copies find the update within a day, or at once with **Check for Updates…**.

## Switching to a Developer ID

When the Apple Developer account has a Developer ID:

1. Install the **Developer ID Application** certificate in the login keychain and store a notarization profile, using an app-specific password for the Apple Account:

   ```sh
   xcrun notarytool store-credentials waft-notary --apple-id <apple-id> --team-id <team-id>
   ```

2. Release with `SIGNING_IDENTITY="Developer ID Application: <name> (<team-id>)"`. The script then signs with the hardened runtime, which needs the microphone entitlement in `Packaging/Waft.entitlements`, notarizes and staples the app and the disk image, and checks the image with `spctl`.
3. Remove `postflight_steps` from `Packaging/Homebrew/waft.rb`, and the **Open Anyway** steps from [Install](getting-started.md#1-install), the README, and [Troubleshooting](troubleshooting.md#macos-wont-open-waft).
4. Say in the release notes that macOS asks once more for the microphone and Accessibility, since the signature changed.

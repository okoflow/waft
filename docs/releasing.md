# Releasing

This page describes how you turn `main` into a release that users get from
GitHub Releases, Homebrew, and in-app updates.
[Checks](../CONTRIBUTING.md#checks) lists what every change passes before it
reaches `main`.

## What a release is made of

| Artifact | Made by | Used by |
| --- | --- | --- |
| `Waft-X.Y.Z.dmg` | `scripts/release.sh`: Developer ID signature, hardened runtime, notarization, stapling | Downloads from GitHub Releases, the Homebrew cask, and Sparkle |
| `appcast.xml` | Sparkle's `generate_appcast`, signed with the project's EdDSA key | Waft's updater, at `releases/latest/download/appcast.xml`, and the cask's `livecheck` |
| `waft.rb` | `scripts/release.sh` from `Packaging/Homebrew/waft.rb` | `Casks/waft.rb` in the `okoflow/homebrew-tap` repository |

Waft is not sandboxed, so the bundle ships Sparkle without its XPC services.
The hardened runtime needs the microphone entitlement in
`Packaging/Waft.entitlements`.

## One-time setup

1. A **Developer ID Application** certificate in the login keychain, from the
   Apple Developer account.
2. A notarization profile in the keychain, using an app-specific password for
   the Apple Account:

   ```sh
   xcrun notarytool store-credentials waft-notary --apple-id <apple-id> --team-id <team-id>
   ```

3. The Sparkle signing key in the login keychain, imported from its offline
   backup with `generate_keys -f <file>`. `generate_keys -p` must then print
   the `SUPublicEDKey` of `Packaging/Waft-Info.plist`:

   ```sh
   swift package resolve
   .build/artifacts/sparkle/Sparkle/bin/generate_keys -p
   ```

   Make the backup with `generate_keys -x <file>` and keep it offline, since
   installed copies verify the feed with this key.

## Cutting a release

1. Merge a pull request titled `chore(release): prepare X.Y.Z` from the
   branch `release/X.Y.Z`. Its one commit,
   `chore(release): bump version to X.Y.Z`, raises
   `CFBundleShortVersionString` to `X.Y.Z` and `CFBundleVersion` by one in
   `Packaging/Waft-Info.plist`. Sparkle compares `CFBundleVersion`, so it must
   always grow.
2. Write the release notes in Markdown: one summary sentence, then `## Added`,
   `## Changed`, and `## Fixed`, leaving out an empty one, then
   `**Contributors**:` with the GitHub handles of the release's commit authors
   and `**Full changelog**:` with the compare link from the previous tag. Keep
   the file outside the repository, since the script needs a clean working
   tree.
3. Build, notarize, and package `main`:

   ```sh
   SIGNING_IDENTITY="Developer ID Application: <name> (<team-id>)" make release NOTES=../notes.md
   ```

   The script stops unless the working tree is clean, `HEAD` is
   `origin/main`, the version's tag isn't on `origin` yet, and the identity,
   notarization profile, and Sparkle key from
   [One-time setup](#one-time-setup) are in place. It notarizes the app and
   the disk image, staples both, and writes the appcast with the notes
   embedded and the cask with the disk image's checksum into `build/release`.
   `generate_appcast` signs the appcast, notes included, so any edit to
   `appcast.xml` breaks the signature: to change it, run `generate_appcast`
   again with the arguments that `make_appcast` in `scripts/release.sh`
   passes.
4. Publish the release with both files attached, using the command the script
   prints, which tags the commit it built. Releases are immutable: once
   published, the tag and the files can't change, and with them the notes
   embedded in the appcast, so check both first.

   ```sh
   gh release create vX.Y.Z build/release/Waft-X.Y.Z.dmg build/release/appcast.xml \
     --target <commit> --title vX.Y.Z --notes-file ../notes.md
   ```

5. Update the cask: copy `build/release/waft.rb` to `Casks/waft.rb` in your
   clone of `okoflow/homebrew-tap`, then commit and push it.

Installed copies find the update within a day, or at once with **Check for
Updates…**.

## Until the first notarized release

Until a Developer ID certificate arrives, a release is source-only: skip steps
3 and 5 of [Cutting a release](#cutting-a-release), and in step 4 drop the two
files and set `--target` to the merge commit of the release pull request. With
the first notarized release:

1. Create the Homebrew tap: a public `okoflow/homebrew-tap` repository with a
   `Casks` folder, which `brew install --cask okoflow/tap/waft` reads.

   ```sh
   gh repo create okoflow/homebrew-tap --public --clone
   mkdir homebrew-tap/Casks
   ```

2. Switch [Install](getting-started.md#1-install) and the README's Install
   section from building from source to `brew install --cask okoflow/tap/waft`
   and the disk image on GitHub Releases, and add
   `brew uninstall --zap --cask waft` to
   [Removing everything](privacy.md#removing-everything).

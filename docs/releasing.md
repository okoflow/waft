# Releasing

This page describes how a maintainer turns `main` into a signed, notarized
release that users get from GitHub Releases, Homebrew, and in-app updates.
[CONTRIBUTING.md](../CONTRIBUTING.md) covers the checks every change passes
before it reaches `main`.

## What a release is made of

| Artifact | Made by | Used by |
| --- | --- | --- |
| `Waft-X.Y.Z.dmg` | `scripts/release.sh`: Developer ID signature, hardened runtime, notarization, stapling | Downloads from GitHub Releases, the Homebrew cask, and Sparkle |
| `appcast.xml` | Sparkle's `generate_appcast`, signed with the project's EdDSA key | Waft's updater, at `releases/latest/download/appcast.xml` |
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

3. The Sparkle signing key in the login keychain. `SUPublicEDKey` in
   `Packaging/Waft-Info.plist` must match it:

   ```sh
   swift package resolve
   .build/artifacts/sparkle/Sparkle/bin/generate_keys -p
   ```

   Keep an offline backup made with `generate_keys -x <file>`. Without the
   key, existing installations can never update again. Waft requires a signed
   feed and verifies each update before extracting it, so rotating the key
   later works only because the disk images carry a Developer ID signature.

4. The Homebrew tap, created once with the first notarized release: a public
   repository named `okoflow/homebrew-tap` with a `Casks` folder, which
   `brew install --cask okoflow/tap/waft` finds by that name:

   ```sh
   gh repo create okoflow/homebrew-tap --public --clone
   mkdir homebrew-tap/Casks
   ```

5. The install instructions, switched once with the first notarized release: the
   Install sections of the README and [Getting started](getting-started.md)
   name `brew install --cask okoflow/tap/waft` and the disk image on GitHub
   Releases instead of building from source.

## Cutting a release

1. Merge a pull request titled `chore(release): prepare X.Y.Z` from the
   branch `release/X.Y.Z`. Its one commit,
   `chore(release): bump version to X.Y.Z`, raises
   `CFBundleShortVersionString` to `X.Y.Z` and `CFBundleVersion` by one in
   `Packaging/Waft-Info.plist`. Sparkle compares `CFBundleVersion`, so it must
   always grow.
2. Write the release notes in Markdown: one summary sentence, then `## Added`,
   `## Changed`, and `## Fixed`, then `**Contributors**:` with the GitHub
   handles and `**Full changelog**:` with the compare link from the previous
   tag. Keep the file outside the repository.
3. Build, notarize, and package `main`:

   ```sh
   SIGNING_IDENTITY="Developer ID Application: <name> (<team-id>)" make release NOTES=../notes.md
   ```

   The script stops unless the working tree has no changes, `HEAD` is
   `origin/main`, and the version's tag doesn't exist yet. It notarizes the
   app and the disk image, staples both, writes the appcast with the notes
   embedded, and writes the cask with the disk image's checksum into
   `build/release`. `generate_appcast` signs the appcast and the notes too.
   Never edit `appcast.xml` afterwards, since any edit breaks that signature;
   run `generate_appcast` again with the arguments that `make_appcast` in
   `scripts/release.sh` passes instead.
4. Publish the release with both files attached, using the command the
   script prints, which tags the commit it built:

   ```sh
   gh release create vX.Y.Z build/release/Waft-X.Y.Z.dmg build/release/appcast.xml \
     --target <commit> --title vX.Y.Z --notes-file ../notes.md
   ```

5. Update the cask: copy `build/release/waft.rb` to `Casks/waft.rb` in your
   clone of `okoflow/homebrew-tap`, then commit and push it.

Installed copies find the update within a day, or at once with **Check for
Updates…**.

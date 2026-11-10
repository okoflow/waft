# Security policy

This page covers how to report a vulnerability in Waft, how the maintainers handle it, and what is in scope. [Privacy](docs/privacy.md) lists what Waft keeps and sends.

## Supported versions

Only the latest release and `main` are supported. If you run an older release, update to the latest one.

## Reporting a vulnerability

Report a vulnerability through [GitHub private vulnerability reporting](https://github.com/okoflow/waft/security/advisories/new), or by email to [contact@svidware.com](mailto:contact@svidware.com) if you can't use GitHub. Don't open a public issue, pull request, or discussion for it.

Include:

- The Waft version or commit, and the macOS version.
- Steps to reproduce, or a proof of concept.
- The impact you expect.

You receive an acknowledgment within three business days and a triage decision within seven. The maintainers keep the report private until a fix is available, and the fix ships with a security advisory that credits you unless you prefer otherwise. Keep the report private until the advisory is published.

## Scope

In scope: everything in this repository, including the app, the scripts, and the build configuration, and the license service at `api.waft.okoflow.com`, which issues Waft+ license keys. Of particular interest:

- Audio leaving the Mac, or text leaving it other than for the AI provider you chose.
- Text pasted into a password field, or into another app than the one you dictated into.
- An API key leaving its owner-only file for anything other than its provider's API.
- Dictated text or clipboard contents reaching the logs, other apps, or the disk outside the files that [Privacy](docs/privacy.md#what-waft-keeps) lists.
- The event tap or the Accessibility access used beyond what dictation needs.
- An update installed without the project's signature, or a license key accepted without a valid signature.
- The license service issuing a key without a purchase, or revealing a buyer's details.

Out of scope: vulnerabilities in WhisperKit, Sparkle, the speech model, or macOS unless Waft's use of them causes the problem; attacks that need an already compromised user account; the Waft Dev identity that `make signing` creates for local builds.

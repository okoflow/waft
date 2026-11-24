# Security policy

This page covers which versions of Waft are supported, how to report a vulnerability, and what is in scope.

## Supported versions

| Version                       | Supported                        |
| ----------------------------- | -------------------------------- |
| The latest release and `main` | Yes                              |
| Older releases                | No, update to the latest release |

## Reporting a vulnerability

Report a vulnerability through [GitHub private vulnerability reporting](https://github.com/okoflow/waft/security/advisories/new), or by email to [contact@svidware.com](mailto:contact@svidware.com) if you can't use GitHub. Don't open a public issue, pull request, or discussion for a security problem.

Include what helps reproduce and assess the issue:

- The Waft version or commit, and the macOS version.
- Steps to reproduce, or a proof of concept.
- The impact you expect.

You receive an acknowledgment within three business days and a triage decision within seven business days. A confirmed vulnerability is fixed in a new release and disclosed in a GitHub security advisory that credits you, unless you ask otherwise. Keep the report private until the advisory is published.

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

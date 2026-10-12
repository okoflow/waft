# Security policy

Waft records your voice, reads the focused text field through
Accessibility, writes to the clipboard, keeps API keys in the Keychain, and
updates itself. The maintainers handle security reports privately until a fix
is available.

## Supported versions

| Version | Supported |
| --- | --- |
| The latest release and `main` | Yes |
| Older releases | No, update to the latest release |

## Reporting a vulnerability

Report vulnerabilities through
[GitHub private vulnerability reporting](https://github.com/okoflow/waft/security/advisories/new).
If you can't use GitHub, email
[contact@svidware.com](mailto:contact@svidware.com) instead. Don't open a
public issue, pull request, or discussion for a security problem.

Include what helps reproduce and assess the issue:

- the Waft version or commit, and the macOS version
- steps to reproduce, or a proof of concept
- the impact you expect

You receive an acknowledgment within three business days and a triage
decision within seven business days. Fixes ship with a security advisory that
credits the reporter unless they prefer otherwise. Please keep the report
private until the advisory is published.

## Scope

In scope: everything in this repository, including the app, the scripts, and
the build configuration, and the license service at `api.waft.okoflow.com`,
which issues Waft Pro license keys. Of particular interest:

- audio leaving the Mac, or text leaving it outside the AI modes
- text pasted into a password field, or into another app than the one you
  dictated into
- an API key leaving the Keychain for anything other than its provider's API
- dictated text or clipboard contents reaching the logs, the disk, or other
  apps
- the event tap or the Accessibility access used beyond what dictation needs
- an update installed without the project's signature, or a license key
  accepted without a valid signature
- the license service issuing a key without a purchase, or revealing a buyer's
  details

Out of scope: vulnerabilities in WhisperKit, Sparkle, the speech model, or
macOS unless Waft's use of them causes the problem; attacks that need an
already compromised user account; the Waft Dev identity that `make signing`
creates for local builds.

## Dependencies

The packages Waft depends on are pinned to exact versions in `Package.swift`,
with every resolved package recorded in `Package.resolved`. Dependabot
proposes updates for them and for the GitHub Actions.

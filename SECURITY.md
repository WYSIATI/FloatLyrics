# Security

Report vulnerabilities privately through
[GitHub security advisories](https://github.com/WYSIATI/FloatLyrics/security/advisories/new).
Please do not publish exploit details, credentials or private playback data in
an issue. Include the app version, macOS version, reproduction steps and impact.

The current release is maintained on a best-effort basis. Fixes are delivered
in the latest release rather than backported to older versions.

Float Lyrics reads track metadata and playback position from the selected local
Spotify or Apple Music app using macOS Automation. It sends the current track's
title, artist, album and duration to LRCLIB over HTTPS. It has no account login,
analytics, event taps or Accessibility permission requirement. Lyrics and
preferences are cached locally. Demo previews use a separate preference domain.

Public preview builds are ad-hoc signed and not notarized. Download only from
this repository's Releases page and compare the published SHA-256 checksum.
The app does not disable Gatekeeper or change system security settings.

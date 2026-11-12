# Changelog

## Unreleased

### Added

- **Check for Updates…** in the menu bar and Settings. Check the latest public
  GitHub release on demand, then open its installer or release notes. The app
  explains how to replace the installed copy while keeping saved settings.
- Clear feedback for an up-to-date app, a local build newer than the public
  release, connection failures and GitHub rate limits. Repeated clicks share
  the in-progress check; local builds never offer an older release as an update.
- A configurable global shortcut in **Settings → Behavior & timing → Show / hide
  lyrics**. Record a combination to toggle lyrics from any app; clear it to
  disable the shortcut. No combination is assigned by default.
- Native debug logs for visibility and shortcut configuration changes, without
  recording song details, lyrics or the chosen combination.

### Changed

- Download and open a DMG directly from the GitHub page or **Check for Updates…**.
  Remove installer ZIPs and the extraction step; release packaging now produces
  DMGs and their checksums.
- The floating window's options menu now labels its hide action **Hide Window**.
  Hiding keeps the menu-bar icon available, with **Show Window** switching back
  to **Hide Window** when restored. Visibility changes preserve the selected
  floating-window or Dynamic Island mode and leave playback running.
- Package the pinned KeyboardShortcuts 3.1.0 dependency, its localized recorder
  resources and MIT license with the app.

## 1.4.2 · Installer identity and verification

- The public installer is signed by Mini Motion AI LLC and notarized by Apple,
  with stapled verification tickets for the app and DMG.
- Use the app's lifted-line F logo for the mounted installer volume and the
  locally generated DMG's Finder icon.
- Provide a ZIP download that preserves the DMG file's Finder logo after
  extraction with macOS's built-in archive utility.
- Require Developer ID signing, accepted Apple notarization, stapled tickets
  and Gatekeeper checks before generating release download aliases.
- Keep explicitly requested unnotarized test installers in `dist/preview/`.
  Include launch recovery instructions only in preview installers.

## 1.4.1 · A little lift

- Quit directly from the floating window's options menu or the expanded island's
  options menu. The island stays open while its menu is in use.
- New lifted-line F identity, with a vector-drawn Mac icon and matching menu-bar,
  notch, settings and first-use marks.
- Clearer secondary lyrics and artist text, a more useful waiting state, and a
  compact settings header with version and help access.
- Refreshed GitHub presentation and a matching social preview.

## 1.4.0 · Float Lyrics

- Renamed the app, menu-bar labels, Automation message, installer volume and app
  bundle to **Float Lyrics**.
- Kept the app identity and saved listening preferences compatible with existing
  installs. Existing download filenames remain as compatibility aliases.
- Added isolated real-playback recording preferences; unlike sample preview mode,
  this reads the current Spotify/Apple Music track and fetches its actual lyrics.
- Retry installer verification only when macOS briefly holds a newly created
  image; other verification failures still stop the release.

## 1.3.1 · Public preview

- MIT-licensed source, public downloads, installation instructions and a macOS
  build workflow.
- Empty exact-match lyric records now fall back to a usable search result.
  Malformed responses have a readable error; whitespace-only lyrics are rejected.
- Expanded island recovery buttons now connect to the player or retry lyrics.
- Original sample previews use separate preferences, preserving listening settings.
- Installer and app bundle include the license. Stable download filename and
  published SHA-256 checksum support public distribution.

## 1.3.0

- Smaller main view with song, current lyric, next line and one menu.
- Settings index with nested appearance, player and behavior/timing pages.

## 1.2.1

- Shared glass style for the lyric window and Settings; neutral text and materials.

## 1.2.0

- Separate window/island opacity and text preferences; compact island sizing.

## 1.1.0

- Physical camera-integrated island, native clear glass and neutral controls.

## 1.0.0

- Local Spotify/Apple Music playback, LRCLIB lyrics and universal Mac installer.

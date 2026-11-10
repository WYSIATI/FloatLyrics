# Changelog

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

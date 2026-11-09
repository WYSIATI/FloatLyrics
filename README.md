# FloatLyrics

A native macOS companion for singing along while you work. Rebuilt from scratch in Swift 6 and SwiftUI, with no third-party dependencies.

Requires macOS 14 or later. Native Liquid Glass is available on macOS 26; earlier systems use a translucent material.

## Development

Open `Package.swift` in Xcode 26 or build with `swift build`. Run the timing and lyrics-service tests with `swift test`.

## Data sources

Playback comes from the selected **desktop** app, Spotify or Apple Music, through macOS Automation. Browser players and playback on other devices are not supported. Lyrics come from [LRCLIB](https://lrclib.net/docs), a free public API without an API key. Only the current track's title, artist, album and duration are sent to LRCLIB. Successfully fetched lyrics are cached locally. Availability and timing depend on the recording and community data.

FloatLyrics is an independent app, unaffiliated with Apple, Spotify or LRCLIB. Lyrics remain the property of their respective owners.

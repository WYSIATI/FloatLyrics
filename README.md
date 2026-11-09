# FloatLyrics

A native macOS companion for singing along while you work. Rebuilt from scratch in Swift 6 and SwiftUI, with no third-party dependencies.

Requires macOS 14 or later. Native Liquid Glass is available on macOS 26; earlier systems use a translucent material.

## Use

1. Open the DMG and drag **FloatLyrics** into **Applications**.
2. Launch it and select **Spotify** or **Apple Music** in the window or menu bar.
3. Play a song in that desktop app. Allow the Automation prompt if macOS asks.

The window defaults to **always on top** at **88% opacity**, without stealing focus. Drag it wherever you like. The sliders button adjusts opacity (25–100%), lyric size, and timing (±5 seconds). Enable click through to work through the overlay; the menu bar always lets you restore interaction, change settings, show hidden lyrics, or quit.

The MacBook button switches to **notch mode**, showing the current line below the camera cutout. The expand button restores the floating view. On displays without a notch, it becomes a compact strip under the menu bar. The physical cutout cannot display text. The strip avoids covering the rest of the menu bar.

Track changes trigger a new lyrics lookup. Playback notifications plus a 750 ms poll detect changes, pause/resume and seeks; a local clock updates line timing between samples. Timed blank lines preserve instrumental breaks. Tracks with plain lyrics get a scrollable, explicitly unsynced view. Missing lyrics and network errors have a retry action. Exact lookup falls back to title/artist search, accepting only matching names and nearby durations; remix/live version tags stay intact.

Window position, source, opacity, size, always-on-top and display mode persist. Timing adjustment resets per song, and click through resets on relaunch so the app is recoverable.

## Development

Open `Package.swift` in Xcode 26 or build with `swift build`. Run the timing and lyrics-service tests with `swift test`.

```sh
bash scripts/build-app.sh     # universal Apple Silicon + Intel .app
bash scripts/package-dmg.sh   # dist/FloatLyrics-1.0.0.dmg + SHA-256
bash scripts/verify-dmg.sh    # mount read-only and verify the packaged app
```

Build scripts need Xcode 26 or later and have no downloaded dependencies. Set `ARCHITECTURE=native` for a faster local build. Launch `build/FloatLyrics.app/Contents/MacOS/FloatLyrics --demo` for an original-lyrics visual preview, or `--diagnostics` for opt-in playback position diagnostics on standard output.

The default package is **ad-hoc signed and unnotarized**. For distribution outside this Mac, use an installed Developer ID certificate and a configured notarization keychain profile:

```sh
SIGNING_IDENTITY='Developer ID Application: …' NOTARY_PROFILE='…' bash scripts/package-dmg.sh
```

The script signs with the hardened runtime and Automation entitlement, notarizes and staples the app, then notarizes and staples the DMG. No credentials or signing certificates belong in the repository. An unnotarized downloaded build may require **System Settings → Privacy & Security → Open Anyway**.

## Permissions and troubleshooting

- If playback access is denied, enable FloatLyrics for the selected player under **Privacy & Security → Automation**, then choose **Reconnect / Refresh Lyrics** in the menu bar.
- Spotify must be running locally. Spotify Connect on another device can report a different clock and is outside the supported playback path.
- Apple Music needs a playable local or streamed song; radio streams without usable metadata may have no match.
- Lyrics cache: `~/Library/Caches/app.floatlyrics.desktop/lyrics`. Preferences: the `app.floatlyrics.desktop` user defaults domain. There is no account login or telemetry.
- Always-on-top works across ordinary apps and Spaces. macOS protected system screens and some exclusive full-screen apps can restrict third-party overlays.

## Data sources

Playback comes from the selected **desktop** app, Spotify or Apple Music, through macOS Automation. Browser players and playback on other devices are not supported. Lyrics come from [LRCLIB](https://lrclib.net/docs), a free public API without an API key. Only the current track's title, artist, album and duration are sent to LRCLIB. Successfully fetched lyrics are cached locally. Availability and timing depend on the recording and community data.

FloatLyrics is an independent app, unaffiliated with Apple, Spotify or LRCLIB. Lyrics remain the property of their respective owners.

# FloatLyrics

A native macOS companion for singing along while you work. Rebuilt from scratch in Swift 6 and SwiftUI, with no third-party dependencies.

Requires macOS 14 or later. Native Liquid Glass is available on macOS 26; earlier systems use a translucent material.

## Use

1. Open the DMG and drag **FloatLyrics** into **Applications**.
2. Launch it and select **Spotify** or **Apple Music** in the window or menu bar.
3. Play a song in that desktop app. Allow the Automation prompt if macOS asks.

The window defaults to **always on top** without stealing focus. Drag it wherever you like. Open **Appearance** with the sliders button, the menu bar, or **⌘,**. Window and Island have independent background opacity (15–100%) and lyric colors: automatic contrast, preset swatches, a native custom color picker and six-digit hex entry. Changes preview live and persist. New installs start with 70% window glass opacity; existing opacity choices are preserved. Text stays crisp as the background fades. Lyric size and timing (±5 seconds) remain adjustable. Enable click through to work through the overlay; the menu bar always restores interaction, settings or hidden lyrics.

The MacBook button switches to **Dynamic Island**. Its default footprint is **320 points wide** with a **24-point single lyric line below the camera**, growing only as needed to fit the camera housing. Width adjusts from 280–400 points. It stays compact when the pointer passes by: click to expand, then move away to auto-collapse after 2.5 seconds. Hover expansion is optional. Expansion is limited to song details, the current lyric and collapse/return controls. On displays without a cutout, it becomes a top-edge island. Space outside its silhouette passes clicks through. The camera cap stays solid black while the lyric area's opacity adjusts independently.

The lyric window and Appearance panel share the same native glass surface, rounded edges, typography and selection controls. **Glass, Smoke and Ink** are neutral materials, with automatic, graphite, charcoal, silver and white lyric presets. Former blue/purple presets and legacy cool custom colors migrate to neutral defaults without changing opacity or island layout. The custom color picker and hex entry remain available for explicit personal choices.

On macOS 26 both panels use AppKit's native `NSGlassEffectView` with clear glass and a behind-window material backdrop. Flat controls and neutral fluid highlights replace embossed chrome; decorative movement happens only on hover and respects Reduce Motion. References: [Vibe Notch](https://github.com/farouqaldori/vibe-notch), [Chahat Soni's liquid-metal button](https://dribbble.com/shots/27633863-Liquid-metal-button-in-Figma) and [Konpo's flowing metal logo](https://dribbble.com/shots/25673199-Konpo-Liquid-Metal-Effect-on-Our-Logo). No reference media assets are bundled.

Track changes trigger a new lyrics lookup. Playback notifications plus a 750 ms poll detect changes, pause/resume and seeks; a local clock updates line timing between samples. Timed blank lines preserve instrumental breaks. Tracks with plain lyrics get a scrollable, explicitly unsynced view. Missing lyrics and network errors have a retry action. Exact lookup falls back to title/artist search, accepting only matching names and nearby durations; remix/live version tags stay intact.

Window position, source, material, opacity, lyric size, both lyric colors, island width, hover preference, always-on-top and display mode persist. Timing adjustment resets per song, and click through resets on relaunch so the app is recoverable.

## Development

Open `Package.swift` in Xcode 26 or build with `swift build`. Run the timing and lyrics-service tests with `swift test`.

```sh
bash scripts/build-app.sh     # universal Apple Silicon + Intel .app
bash scripts/package-dmg.sh   # dist/FloatLyrics-1.2.1.dmg + SHA-256
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

# Validation · 2026-11-09

- Xcode 26.6 / Swift 6.3.3; deployment target macOS 14.
- Universal release build compiles for arm64 and x86_64.
- 16 automated tests pass: LRC timestamps, Unicode, repeated tags, offsets, blank instrumental breaks, seek boundaries, pause clock, exact recording matching, featured tags, cache, missing/unsynced lyrics, rate-limit handling, permission classification, both player dictionaries, and physical-screen notch geometry on built-in/external displays.
- Live Spotify on this Mac detected track changes automatically, fetched LRCLIB synchronized lyrics, and displayed advancing lines in both floating and notch modes.
- Native controls verified: opacity adjustment, timing adjustment, notch transition and expansion, and pause/resume indication. Spotify backward seeking was exercised while monitoring the app's playback position and current lyric.
- A recording absent from LRCLIB correctly displayed a no-lyrics state with retry.
- Switching to Apple Music cleared Spotify's track and lyrics and showed the correct waiting state; switching back restored the current Spotify song and cached lyrics.
- The compressed DMG checksum passed `hdiutil verify`.
- A read-only DMG mount verified the Applications shortcut, installation note, app icon, bundle metadata, both executable architectures and strict code signature, then detached cleanly.

Apple Music's scripting dictionary was verified locally; an active Apple Music subscription/streamed playback session was not supplied for an end-to-end music test. Earlier macOS material fallback and Intel execution were compiled but not run on separate hardware.

The default distributable is ad-hoc signed. Developer ID notarization requires a certificate and Apple notarization credentials; none are embedded or created by the project.

## 1.1 interface revision

- Replaced the detached below-notch panel with a physical-top-edge island that spans the camera region. Camera width is measured with the auxiliary menu areas; the center header space stays empty behind the camera.
- Compact and expanded views share a black silhouette with concave shoulders. Hover opens temporarily, click pins it open, collapse and return-to-window controls remain available.
- Areas outside the visible silhouette pass mouse events through. No event taps, synthetic mouse reposting or extra input permissions are used.
- Replaced the forced dark/green UI with a silver interface, clear native AppKit Liquid Glass, desktop material backdrop, moving player selection and neutral icon. Background opacity is independent of lyric opacity.
- On-device visual checks confirmed compact/expanded island silhouettes, click-to-pin, return-to-window controls, live lyrics and the new player selector. Original preview lyrics were used for release screenshots.
- The 1.1 universal DMG passed checksum verification and a read-only mounted-content/signature check.

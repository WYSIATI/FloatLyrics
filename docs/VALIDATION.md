# Validation · 2026-11-09

- Xcode 26.6 / Swift 6.3.3; deployment target macOS 14.
- Universal release build compiles for arm64 and x86_64.
- 14 automated tests pass: LRC timestamps, Unicode, repeated tags, offsets, blank instrumental breaks, seek boundaries, pause clock, exact recording matching, featured tags, cache, missing/unsynced lyrics, rate-limit handling, permission classification and compilation against both installed player dictionaries.
- Live Spotify on this Mac detected track changes automatically, fetched LRCLIB synchronized lyrics, and displayed advancing lines in both floating and notch modes.
- Native controls verified: opacity adjustment, timing adjustment, notch transition and expansion, and pause/resume indication. Spotify backward seeking was exercised while monitoring the app's playback position and current lyric.
- A recording absent from LRCLIB correctly displayed a no-lyrics state with retry.
- Switching to Apple Music cleared Spotify's track and lyrics and showed the correct waiting state; switching back restored the current Spotify song and cached lyrics.
- The compressed DMG checksum passed `hdiutil verify`.
- A read-only DMG mount verified the Applications shortcut, installation note, app icon, bundle metadata, both executable architectures and strict code signature, then detached cleanly.

Apple Music's scripting dictionary was verified locally; an active Apple Music subscription/streamed playback session was not supplied for an end-to-end music test. Earlier macOS material fallback and Intel execution were compiled but not run on separate hardware.

The default distributable is ad-hoc signed. Developer ID notarization requires a certificate and Apple notarization credentials; none are embedded or created by the project.

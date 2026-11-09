# Validation · 2026-11-09

- Xcode 26.6 / Swift 6.3.3; deployment target macOS 14.
- Universal release build compiles for arm64 and x86_64.
- 24 automated tests pass: lyrics/timing/network behavior, both player dictionaries, camera-aware island bounds, independent appearance persistence, malformed/older preferences, custom hex validation, automatic-color contrast, legacy accent migration, and grayscale-only shipped presets/materials.
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

## 1.2 appearance and compact island

- On-device checks verified window opacity and lyric swatches, live custom hex color entry, separate island opacity/width/color, and persistence after application relaunch. Switching profile tabs kept their colors independent.
- The native Appearance window opens with Command-comma; its main controls and live preview were inspected at normal display size. Existing user-selected opacity was retained.
- The compact island defaults to 320 points wide, with a 24-point lyric extension. Camera clearance and screen containment are checked across multiple screen/camera widths and width preferences. Expanded height is constrained to camera height plus 104 points.
- Passing the pointer over the island does not expand it by default. Click expansion collapses 2.5 seconds after the pointer leaves; hover expansion is an explicit preference. Areas outside the silhouette continue passing clicks through.
- Glacier, Midnight and Lavender palettes replace the raised chrome treatment. Fluid accent motion is limited to hover and respects Reduce Motion. The camera cap remains opaque while the lyric extension fades independently.
- The 1.2 universal DMG passed checksum, mounted installer-content and strict app-signature verification.

## 1.2.1 consistent neutral styling

- The lyric and Appearance panels use the same glass-card style and segmented control component. All settings entry points open the same borderless glass panel, with a matching close button and dark/light appearance.
- Shipped material and text colors are grayscale. Glass, Smoke and Ink replace the colored materials. Graphite, charcoal, silver and white replace the blue/purple text presets; the icon and accent reflections are neutral as well.
- Legacy colored preset/custom selections are migrated while opacity and island size remain unchanged. Explicit new custom color choices still use the native picker and hex field.
- On-device inspection confirmed the borderless glass Appearance panel, neutral segmented control, grayscale swatches and slider tint, and migrated island text color. The live window/island previews retain independent controls.
- The 1.2.1 universal DMG passed checksum verification and a read-only mount verified installer contents, both architectures and the strict app signature.

## 1.3 simple primary interface

- Reduced the floating card from 440 × 304 to 400 × 224 points. It shows the song, current lyric, next line and one options menu. Branding, waveform, playback animation, source switcher and provider/sync badges were removed from the primary view.
- Player selection, island mode, Settings and Hide remain in the options menu. The menu bar follows the same hierarchy, with player actions in a submenu.
- Settings starts at a compact three-row index. Appearance exposes only the profile, opacity and text presets; custom colors, material, type size and island layout live under More options. Playback connection and behavior/timing have their own pages. Decorative previews were removed.
- On-device checks verified live Spotify lyrics, the main menu opening Settings at its root, both appearance detail profiles, the music and behavior pages, resizing, visible Back controls, and Escape stepping back through nested pages. Existing opacity, color and island width choices were retained.
- All 24 existing playback, lyrics, appearance and geometry tests pass. No new tests were added for this visual/navigation change.
- The 1.3.0 universal release compiled for both architectures. Its DMG passed checksum verification and a read-only installer-content/strict-signature check. The packaged app's primary view was visually inspected with original sample lyrics.

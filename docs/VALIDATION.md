# Validation

## 1.5.0 signed release · 2026-11-12

- All 48 Swift tests pass against the release source. GitHub Actions run
  `43141932839` also passed for source commit `febd281`; the release preparation
  changes only documentation and the changelog.
- The universal app is signed by Mini Motion AI LLC with Developer ID,
  hardened runtime and the existing Automation entitlement. Apple accepted app
  submission `222e559c-3ea5-417e-afb7-d6013382bb59` and DMG submission
  `2d08e6d7-d5d7-4396-837e-2f246ab2962d`. Both tickets were stapled and validated.
- The 1.5.0 DMG passes Gatekeeper as `Notarized Developer ID`. A read-only mount
  verifies version 1.5.0/build 10, both executable architectures, app signature,
  recorder resources and license, matching volume artwork and app distribution
  policy. `syspolicy_check distribution` reports the app ready for distribution.
- The versioned installer and both DMG aliases have SHA-256
  `db5c7e57e1a4460f1dc1cd23ee48c7b0d92a9e5db1d29e013ec6bea3ed38ec2f`.
  Only DMGs and their checksum files are prepared for upload.
- The interactive checks documented below remain unperformed in this session
  because the computer-use tool is unavailable. No new physical shortcut,
  visual-layout, Apple Music subscription, Intel-hardware or older-macOS runtime
  verification is claimed for this release.

## Direct DMG downloads · 2026-11-12

- The primary README download now uses the latest release's `Float-Lyrics.dmg`
  alias. Installation is three steps with no archive extraction. Release notes
  and maintainer instructions use the same direct-DMG workflow.
- All 48 Swift tests pass. Update tests verify versioned-DMG selection, fallback
  to an uploaded DMG alias, and ignoring ZIPs even when they are the only usable
  archive. The dialog offers a DMG download with manual replacement instructions.
- The real update client successfully queried GitHub and selected
  `Float-Lyrics-1.4.2.dmg` from the current public release. Original public release
  assets were downloaded and verified against their published checksums before
  changing the release's download instructions and checksum manifest.
- The regenerated universal 1.5.0 preview passes strict app-signature, DMG
  checksum and read-only mounted-content checks. All three DMG output checksums
  pass. Packaging removes the current version's obsolete ZIP/checksum and ZIP
  alias, and no longer generates or lists installer archives. The retired
  archive helper was removed. Internal notarization uploads still use Apple's
  accepted archive format.

## Unreleased manual update checks · 2026-11-12

- All 48 Swift tests pass. Thirteen new tests cover numeric version ordering,
  rejecting draft/prerelease/malformed releases, archive and DMG selection,
  safe repository URLs, missing installers, HTTP and connection failures,
  duplicate clicks, retry, dialog actions and avoiding downgrade offers.
- The real `ReleaseUpdateClient` contacted GitHub's public latest-release API
  successfully using its configured API version. It found public version 1.4.2,
  selected `Float-Lyrics-1.4.2.dmg.zip`, constructed the matching release-notes
  URL, and correctly identified local version 1.5.0 as newer. This verified
  release discovery and link selection, not downloading or installing an update.
- Source builds now report version 1.5.0, build 10. The universal arm64/x86_64
  app passes strict code-signature checks. Its local preview DMG passes checksum
  and read-only mounted checks, including both architectures, resource bundles,
  licenses and volume artwork; its ZIP preserves DMG bytes and Finder metadata.
  The preview is ad-hoc signed. No 1.5.0 public release or notarization is claimed.
- Update requests occur only after an explicit user action, use an ephemeral
  cookie-free session and send no playback data or preferences. Native logs use
  subsystem `app.floatlyrics.desktop`, category `Updates`.
- Menu/Settings clicks, dialog appearance, browser handoff and updated Settings
  screenshots remain pending because the computer-use tool is unavailable.

Manual acceptance checklist:

1. Choose **Check for Updates…** from the menu bar and from the Settings footer.
   Confirm both disable further checks while a request or its result is active,
   then allow another check after dismissing the dialog.
2. Verify equal/current and newer-local-build messages. With an older build,
   check **Download Update…**, **Release Notes…**, and **Later**/Escape. The
   download should open the official installer in the default browser.
3. Repeat while lyrics are hidden and in island mode. Confirm the menu-bar
   icon stays accessible and checking for updates preserves the display mode.
4. Disconnect temporarily and verify a readable failure, the **Open Releases…**
   fallback, and a successful retry. Inspect the 326-point Settings root and
   capture an original-demo screenshot before public release.

## Unreleased window visibility and shortcuts · 2026-11-12

- All 35 Swift tests pass. Eight new regression tests cover floating-window and
  island hide/show transitions, menu labels, explicit mode changes while hidden,
  shortcut replacement/removal/persistence, malformed saved shortcuts, visible
  startup and preserving demo playback while hidden. Tests use isolated
  preferences and original demo lyrics.
- Native arm64 and universal arm64/x86_64 app builds pass strict code-signature
  verification. Both use Xcode's SwiftPM resource-bundle lookup; the packaged
  recorder resources live in `Contents/Resources`, alongside its MIT license.
- The local preview DMG passes checksum verification and a read-only mounted
  check of both architectures, app signature, recorder resources, licenses and
  matching volume artwork. Its ZIP preserves the DMG bytes and Finder metadata.
  This is an ad-hoc-signed development preview, not a notarized public release.
- KeyboardShortcuts is pinned to 3.1.0 in the manifest and lockfile. No global
  combination is assigned by default. Preview shortcuts use the same isolated
  preferences as other preview settings.
- Native debug logs use subsystem `app.floatlyrics.desktop` and category
  `WindowPresentation`. They report visibility, display mode and whether a
  shortcut is assigned; they do not include song details, lyrics or key values.
- Interactive verification and new screenshots remain pending: the computer-use
  tool became unavailable before the app could be exercised. The automated tests
  above validate model behavior, not physical key delivery or visual layout.

Manual acceptance checklist:

1. In a `--demo` instance, choose **••• → Hide Window**. Confirm the floating
   window disappears, no island appears, and the menu-bar icon remains. Open its
   menu, choose **Show Window**, and confirm the item changes to **Hide Window**.
2. In **Settings → Behavior & timing**, record a combination under **Show / hide
   lyrics**. Switch to another app and use it to hide and restore lyrics. Hold
   the keys to check it toggles once. Verify the displayed menu shortcut works
   while the menu is open without toggling twice.
3. Replace the combination and confirm the old one stops working. Re-record the
   current combination, cancel recording with Escape, and try a system/menu
   conflict. Clear the field and confirm the shortcut is disabled. Relaunch and
   verify the saved assignment or cleared state.
4. Hide in island mode and restore it with the shortcut. Change display mode
   from the menu while hidden and confirm the selected presentation appears.
   Repeat hide/show with click through enabled and while Settings is open.
5. Inspect the behavior page at native scale, including its recorder and timing
   controls, and capture original-demo screenshots before public release.

## 1.4.2 installer packaging · 2026-11-10

- The recommended download is now a metadata-preserving `.dmg.zip` archive.
  Local creation/extraction verified the DMG bytes, complete FinderInfo and
  icon resource fork are unchanged, with the custom-icon flag still enabled.
  This addresses the DMG file's logo; direct HTTP DMG downloads lose that
  file-level metadata even though their mounted volume keeps its artwork.
- The ZIP was uploaded to GitHub `v1.4.2`, downloaded without authentication,
  marked with browser quarantine and expanded through Finder using Archive
  Utility. The extracted DMG visibly has the F logo. Its SHA-256 matches the
  notarized original, its icon resource fork matches byte-for-byte, and its
  Finder custom-icon flag is enabled. The README now links to this ZIP.
- All 27 existing Swift tests passed on the release Mac.
- The universal preview installer passed checksum, mounted-content, both-
  architecture and strict app-signature checks. Its `.VolumeIcon.icns` matches
  the app icon byte-for-byte and the mounted volume has its custom-icon flag.
- The generated DMG and local aliases have Finder custom-icon metadata. A
  second copy made without extended metadata still passed mounted-volume logo
  verification, checking the logo survives a data-only download.
- Release packaging rejects missing signing/notarization configuration and a
  reused ad-hoc-signed app. Stubbed notary responses confirmed that `Invalid`
  and `In Progress` stop before stapling, while `Accepted` staples and validates.
- A Developer ID Application certificate for Mini Motion AI LLC was issued and
  installed. The universal app is signed with hardened runtime, the Automation
  entitlement and an Apple secure timestamp; strict signature verification
  passed for both architectures outside the restricted workspace.
- Apple accepted the app submission
  `7eefba2d-3782-4723-8880-19f87fc737f9` and DMG submission
  `8ea20585-296d-4909-9707-0fa5ef94965c`. Both notarization tickets were stapled
  and validated. The DMG passes Gatekeeper with `Notarized Developer ID`, and
  its mounted app passes `syspolicy_check distribution`.
- The final 1.4.2 versioned installer and both stable aliases pass SHA-256
  verification and have identical contents. A data-only copy with download
  quarantine applied also passed DMG/app policy, stapled-ticket, both-
  architecture and matching-volume-logo checks.
- The versioned 1.4.2 DMG and both stable aliases have SHA-256
  `6851fb8ec1bf00e0c271dc023b6da4702c67b5529e6f8efdf92a08531ec71df9`.
- Published GitHub release `v1.4.2` as latest. The published README's versioned
  link and both `releases/latest` compatibility links were downloaded without
  authentication. All three public files match the checksum above. The actual
  downloaded DMG, with quarantine applied, passed the full installer verifier,
  including mounted artwork, stapled tickets and macOS distribution checks.
- GitHub Actions run `42779414800` passed for release commit `74e0d95`.
- The local Applications folder still contained the ad-hoc-signed 1.4.1 app.
  It was backed up and replaced with the verified public 1.4.2 download; the
  installed app passes strict signature, stapled-ticket, Gatekeeper and
  `syspolicy_check distribution` checks. A launched process matches the installed
  release executable. Automated accessibility inspection timed out, so no new
  visual or playback verification is claimed here.
- An old 1.4.1 installer was also still mounted from Downloads without a custom
  volume icon. It was replaced by the 1.4.2 installer, whose volume artwork
  matches the installed app. The local Downloads DMG received its Finder icon;
  public HTTP downloads still have the file-metadata limitation documented in
  the release guide.

## 1.4.1 identity and presentation · 2026-11-10

- The lifted-line F is rendered from vector paths for the Mac icon, menu-bar
  template, notch, settings and connection state. All ten ICNS input sizes are
  generated individually; SVG and transparent PNG exports are included.
- Native app captures verified the floating window, compact notch and branded
  settings root with version/help access. Light and Ink settings appearances and
  appearance back navigation were inspected. Public captures use isolated demo
  preferences and original product-demo text.
- The social card was generated using the repository-aware
  `morluto/generate-social-preview` workflow, inspected at full size and at
  640 × 320, normalized to 1280 × 640 with its helper, and saved in GitHub's
  repository social-preview setting. It is a composed illustration based on the
  app; the separate interface screenshots are native captures.
- The universal 1.4.1 build and compressed installer passed checksum verification,
  read-only mounted contents, arm64/x86_64 architecture and strict app-signature
  checks. Existing signing and platform-validation limitations below still apply.
- All 27 existing tests passed against the final source.

## Earlier validation

- Xcode 26.6 / Swift 6.3.3; deployment target macOS 14.
- Universal release build compiles for arm64 and x86_64.
- 27 automated tests pass: lyrics/timing/network behavior, both player dictionaries, camera-aware island bounds, independent appearance persistence, malformed/older preferences, custom hex validation, automatic-color contrast, legacy accent migration, grayscale-only shipped presets/materials, empty-record fallback and malformed service responses.
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

## 1.3.1 public-release review

- Reviewed playback sampling, cancellation on track/source changes, lyric matching/cache behavior, island geometry/pointer containment, preference migration and nested settings navigation. Fixed the empty-record fallback and added readable invalid-response errors and whitespace-only rejection.
- Added connect/open/retry actions to expanded-island recovery states; the compact footprint is unchanged. Native normal-state window and compact/expanded island layouts were inspected with original sample lyrics.
- Preview mode uses a separate preferences domain. A before/after SHA-256 comparison of exported listener preferences confirmed that capturing window, opacity, settings and island scenes did not change listener preferences.
- The local universal DMG passed checksum, license-content, version, both-architecture and strict app-signature checks.
- GitHub Actions run 42636030937 passed all 27 tests, universal packaging and read-only installer verification on a clean macOS 26 runner.
- The 14 original milestone commits and five annotated release tags were polished using the GitHub privacy identity. Each rewritten commit's source tree was compared with its original; a complete private backup is kept outside tracked files. No coauthor trailers were added.

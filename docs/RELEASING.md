# Releasing Float Lyrics

1. Update the version/build number in `Resources/Info.plist` and the changelog.
2. Run `swift test`, then `bash scripts/package-dmg.sh`.
3. Run `bash scripts/verify-dmg.sh` and check live Spotify playback, the lyric
   window, compact/expanded island, Settings navigation and a recovery state.
4. Commit the release with a GitHub privacy email and no coauthor trailer.
5. Tag the tested commit. Upload `dist/Float-Lyrics.dmg`, the compatibility alias
   `dist/FloatLyrics.dmg`, and
   `dist/SHA256SUMS.txt` to that release. Keep the repository public so anonymous
   users can download through the README's stable latest-release link.
   If including launch media, run `bash marketing/build.sh`, add the media files
   to `SHA256SUMS.txt`, and upload the MP4, poster and optional captions too.
6. Download the published DMG without authentication, compare its checksum and
   run the installer verifier against that downloaded copy.

The app targets macOS 14+; native Liquid Glass needs macOS 26+. The DMG contains
both arm64 and x86_64 executables. Compiling for Intel or an older deployment
target does not prove runtime behavior on that hardware/OS.

## Signing

The default build is an explicitly labeled **public preview**: ad-hoc signed,
not notarized. Users may need System Settings → Privacy & Security → Open Anyway
after attempting to open it. Do not recommend disabling Gatekeeper or removing
quarantine attributes.

For a notarized distribution, install a Developer ID Application certificate
and configure a notarization keychain profile, then run:

```sh
SIGNING_IDENTITY='Developer ID Application: …' NOTARY_PROFILE='…' bash scripts/package-dmg.sh
```

The existing script signs with hardened runtime and the Automation entitlement,
notarizes/staples the app, then notarizes/staples the DMG. An Apple Development
certificate is not a substitute for Developer ID distribution signing. Never
commit certificates, credentials, keychain exports or private history backups.

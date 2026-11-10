# Releasing Float Lyrics

1. Update the version/build number in `Resources/Info.plist` and the changelog.
2. Run `swift test`, then the signed release command under Signing below.
   Packaging verifies the completed installer before updating download aliases.
3. Check live Spotify playback, the lyric
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

Locally built apps (`scripts/build-app.sh`) remain ad-hoc signed by default.
**Release DMG packaging requires Developer ID signing and notarization** and
stops immediately if its configuration is missing. An ad-hoc signature passing
`codesign --verify` proves bundle integrity; it does not establish Gatekeeper
acceptance for downloaded apps.

### One-time setup on the release Mac

1. Use an active Apple Developer Program account. In **Xcode → Settings → Apple
   Accounts**, add the account, select its paid developer team and open **Manage
   Certificates**. Create a **Developer ID Application** certificate. If the
   existing certificate was created on another Mac, import its certificate and
   private key instead. Apple requires the Account Holder role to create these
   certificates through the developer account.
2. Confirm that `security find-identity -v -p codesigning` lists
   `Developer ID Application: Your Name (TEAMID)`. Apple Development, Apple
   Distribution and Developer ID Installer certificates cannot sign this app
   for direct distribution.
3. Create an app-specific password at **account.apple.com → Sign-In and
   Security → App-Specific Passwords**, then run the following in Terminal:

   ```sh
   xcrun notarytool store-credentials FloatLyrics
   ```

   Enter the Apple Account, Team ID and app-specific password into the local
   prompts. The tool validates and stores the credentials in Keychain. Do not
   paste passwords into chat, shell history or repository files.
4. Package the release using the exact certificate name from step 2:

```sh
SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE=FloatLyrics bash scripts/package-dmg.sh
```

The script signs with hardened runtime and the Automation entitlement, checks
for an explicit `Accepted` notarization result, staples and validates the app
ticket, then signs, notarizes and staples the DMG. The final verifier checks the
DMG signature/ticket, macOS policy acceptance, matching volume icon, both
architectures, app integrity/ticket and `syspolicy_check distribution`. Stable
download aliases and checksums are updated only after verification passes.

Developer ID signing without notarization does not resolve the reported
“Apple could not verify” warning. Signing the DMG alone does not replace signing
and notarizing the app copied into Applications. Actual Apple service and
Gatekeeper results must pass before claiming a notarized release.

Apple references: [Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates),
[notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).
Never commit certificates, credentials, keychain exports or private history backups.

### Test previews without credentials

```sh
DISTRIBUTION=preview bash scripts/package-dmg.sh
DISTRIBUTION=preview bash scripts/verify-dmg.sh
```

These explicitly unnotarized installers are written to `dist/preview/` with
`-preview` in the versioned filename. CI builds this mode without credentials.
They still trigger the macOS warning after download. Preview installation notes
explain **System Settings → Privacy & Security → Open Anyway** after the first
launch attempt; see [Apple's instructions](https://support.apple.com/en-us/102445).

### Installer logo

The mounted installer's `.VolumeIcon.icns` is copied directly from the signed
app's `AppIcon.icns`, with the volume's custom-icon flag enabled. This logo is
inside the disk image and survives downloads. The local DMG file also receives
the same Finder icon before signing. That file-level Finder icon is extended
metadata, which browsers and hosting services may discard; the mounted volume
and app still retain their logos.

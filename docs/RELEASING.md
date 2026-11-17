# Releasing Float Lyrics

1. Update the version/build number in `Resources/Info.plist`, the changelog and
   the README's release details/checksum links. The primary download uses the
   latest release's `Float-Lyrics.dmg` alias.
2. Run `swift test`, then the signed release command under Signing below.
   Packaging verifies the completed installer before updating download aliases.
3. Check live Spotify playback, the lyric
   window, compact/expanded island, Settings navigation and a recovery state.
   Choose **Check for Updates…** from both Settings and the menu bar. Confirm
   the app compares against the installed version and offers the published
   versioned `.dmg` installer. Keep release tags in `vX.Y.Z`
   format and mark test previews as prereleases so update checks skip them.
4. Commit the release with a GitHub privacy email and no coauthor trailer.
5. Tag the tested commit. Upload the versioned DMG and its `.sha256` file,
   `dist/Float-Lyrics.dmg`,
   the compatibility alias `dist/FloatLyrics.dmg`, and `dist/SHA256SUMS.txt`.
   Publish it as the latest release. Keep the repository public so anonymous
   users can download through the README's direct DMG link and the
   compatibility latest-release links.
   If including launch media, run `bash marketing/build.sh`, add the media files
   to `SHA256SUMS.txt`, and upload the MP4, poster and optional captions too.
6. Download through the published README link without authentication and verify
   the DMG checksum. Run the installer verifier against that downloaded copy.
   Also download both compatibility filenames through `releases/latest` and
   verify they match the same notarized version. Local verification alone does
   not update or validate the public download.

The app targets macOS 14+; native Liquid Glass needs macOS 26+. The DMG contains
both arm64 and x86_64 executables. Compiling for Intel or an older deployment
target does not prove runtime behavior on that hardware/OS.

## Mac App Store

The store build uses the Music category and bundle ID `app.floatlyrics.desktop`.
It enables App Sandbox, outbound HTTPS and Apple Events to the two players.
It declares the keyboard shortcut and appearance preferences in its required-reason
API manifest. The `APP_STORE` compilation condition removes the GitHub updater.

With a configured Xcode, build a locally signed sandboxed copy to exercise the
store UI, playback and Automation permission flow on your Mac:

```sh
bash scripts/build-app.sh --app-store
open "build/app-store/Float Lyrics.app"
```

Use the installed Spotify and Music desktop apps separately. Check a playing,
paused and seeked track, the lyric lookup, window and island, the shortcut,
and the denial/reconnect path for each player. Spotify publishes the
`com.spotify.playback` and `com.spotify.library` scripting groups. Music
publishes `com.apple.Music.playback` and `com.apple.Music.library.read`.
Float Lyrics reads the current track's fields and timing through these groups.

### Xcode Organizer

After building the release Store app, sign in to the seller’s team in
**Xcode → Settings → Apple Accounts** and register the explicit bundle ID.
To sign and archive the verified binary with the account available in Xcode,
prepare its native project and open the path printed by the command.

```sh
python3 scripts/archive-app-store.py --team-id YOURTEAMID --prepare-project
```

Choose the **Float Lyrics** scheme. Under the target’s **Signing & Capabilities**,
verify the team, bundle identifier and automatic signing selection. Choose
**Product → Archive**. Xcode signs the app for the team and copies the matching
debug symbols into the archive. In Organizer, choose **Distribute App → App Store
Connect**. Xcode can use cloud-managed distribution certificates with the team’s
permissions. [Apple’s cloud-managed certificates](https://developer.apple.com/help/account/certificates/cloud-managed-certificates/)

To perform the same archive step from a shell that can access the Xcode account
and signing keychain, run the command without `--prepare-project`. Both commands
write matching `*-ExportOptions.plist` settings into `dist/app-store/`. For a
local Store export, pass the team-signed archive and that file to
`xcodebuild -exportArchive -allowProvisioningUpdates` with an `-exportPath`.
The export options preserve the build number. Running the script without
`--team-id` packages the local build for inspection.

### Signed installer package

To create the upload package, register the explicit bundle ID for the seller's
team. Install both signing identities and their private keys on the build Mac.
Run `security find-identity -v` for their full names. Set `SIGNING_KEYCHAIN`
if they are stored in a separate keychain. For TestFlight, set `STORE_PROFILE`
to the Mac App Store distribution profile for this app. This build's sandbox
and hardened-runtime entitlements also support direct App Store submission
without a profile. [Apple's provisioning profile rules](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)

```sh
STORE_APP_IDENTITY='Apple Distribution: Your Team (TEAMID)' \
STORE_INSTALLER_IDENTITY='3rd Party Mac Developer Installer: Your Team (TEAMID)' \
bash scripts/package-app-store.sh
```

The signed package is written to `dist/app-store/Float-Lyrics-<version>-<build>.pkg`.
Use Transporter to verify and deliver it to the macOS app record. Wait for
processing, then select that build on the version page. Each subsequent upload
requires a higher build number in `Resources/Info.plist`.
[Apple's packaging instructions](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution)
and [submission fields](app-store/submission.md).

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
   An HTTP 401 error means Apple rejected the credential and the profile was
   not saved. Generate a fresh app-specific password while signed into the
   same Apple Account used for `--apple-id`, then paste its complete generated
   value into the local prompt. The password's descriptive label is not the
   password. Do not use `--no-validate` to skip a failed authentication check.
4. Package the release using the exact certificate name from step 2:

```sh
SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE=FloatLyrics bash scripts/package-dmg.sh
```

For a release key stored in a separate keychain, set `SIGNING_KEYCHAIN` to its
path. Both app and DMG signing use that keychain. `NOTARY_PROFILE` identifies the
notarization credential. If it was saved using `notarytool --keychain`, set
`NOTARY_KEYCHAIN` to that same keychain path when packaging; otherwise Apple’s
tool uses the data protection keychain (iCloud or Local Items). For example:

```sh
SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE=FloatLyrics \
NOTARY_KEYCHAIN="$HOME/Library/Keychains/login.keychain-db" \
bash scripts/package-dmg.sh
```

The release keychain must
be unlocked and permit Apple's signing tools to use its release key. Configure
only the dedicated release keychain, without changing access to unrelated keys.

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

Public downloads use the DMG directly. Its file icon may use macOS's standard
disk-image artwork; opening the DMG still shows the branded installer and app.

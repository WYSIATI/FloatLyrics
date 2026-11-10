#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then bash scripts/build-app.sh; fi
app="$PWD/build/Float Lyrics.app"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
mkdir -p dist
staging="$(mktemp -d "${TMPDIR:-/tmp}/floatlyrics-dmg.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
ditto "$app" "$staging/Float Lyrics.app"
ln -s /Applications "$staging/Applications"
cp Resources/Install.txt "$staging/Read me.txt"
cp LICENSE "$staging/License.txt"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    ditto -c -k --keepParent "$app" build/FloatLyrics-notarize.zip
    xcrun notarytool submit build/FloatLyrics-notarize.zip --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$app"
    ditto "$app" "$staging/Float Lyrics.app"
fi

output="$PWD/dist/Float-Lyrics-$version.dmg"
hdiutil create -volname "Float Lyrics" -srcfolder "$staging" -format UDZO -ov "$output"
if [[ -n "${SIGNING_IDENTITY:-}" && "$SIGNING_IDENTITY" != "-" ]]; then
    codesign --sign "$SIGNING_IDENTITY" --timestamp "$output"
fi
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$output" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$output"
fi
hdiutil verify "$output"
(
    cd dist
    shasum -a 256 "Float-Lyrics-$version.dmg" > "Float-Lyrics-$version.dmg.sha256"
)
printf 'Packaged %s\n' "$output"
cp "$output" "$PWD/dist/Float-Lyrics.dmg"
# Keep existing public download links working.
cp "$output" "$PWD/dist/FloatLyrics.dmg"
(
    cd dist
    shasum -a 256 Float-Lyrics.dmg FloatLyrics.dmg > SHA256SUMS.txt
)

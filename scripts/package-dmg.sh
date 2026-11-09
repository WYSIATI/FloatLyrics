#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then bash scripts/build-app.sh; fi
app="$PWD/build/FloatLyrics.app"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
mkdir -p dist
staging="$(mktemp -d "${TMPDIR:-/tmp}/floatlyrics-dmg.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
ditto "$app" "$staging/FloatLyrics.app"
ln -s /Applications "$staging/Applications"
cp Resources/Install.txt "$staging/Read me.txt"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    ditto -c -k --keepParent "$app" build/FloatLyrics-notarize.zip
    xcrun notarytool submit build/FloatLyrics-notarize.zip --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$app"
    ditto "$app" "$staging/FloatLyrics.app"
fi

output="$PWD/dist/FloatLyrics-$version.dmg"
hdiutil create -volname FloatLyrics -srcfolder "$staging" -format UDZO -ov "$output"
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
    shasum -a 256 "FloatLyrics-$version.dmg" > "FloatLyrics-$version.dmg.sha256"
)
printf 'Packaged %s\n' "$output"

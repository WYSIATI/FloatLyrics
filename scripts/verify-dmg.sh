#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
image="${1:-$PWD/dist/FloatLyrics-$version.dmg}"
mount="$(mktemp -d "${TMPDIR:-/tmp}/floatlyrics-verify.XXXXXX")"
cleanup() {
    hdiutil detach "$mount" -quiet || true
    rmdir "$mount" || true
}
trap cleanup EXIT
hdiutil attach -readonly -nobrowse -mountpoint "$mount" "$image"
app="$mount/FloatLyrics.app"
test -x "$app/Contents/MacOS/FloatLyrics"
test -f "$app/Contents/Resources/AppIcon.icns"
test -f "$app/Contents/Resources/LICENSE.txt"
test "$(readlink "$mount/Applications")" = /Applications
test -f "$mount/Read me.txt"
test -f "$mount/License.txt"
plutil -lint "$app/Contents/Info.plist"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "$version"
lipo "$app/Contents/MacOS/FloatLyrics" -verify_arch arm64 x86_64
codesign --verify --deep --strict "$app"
printf 'Installer contents, universal executable, and app signature verified.\n'

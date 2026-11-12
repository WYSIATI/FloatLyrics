#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
distribution="${DISTRIBUTION:-release}"
case "$distribution" in
    release) default_image="$PWD/dist/Float-Lyrics-$version.dmg" ;;
    preview) default_image="$PWD/dist/preview/Float-Lyrics-$version-preview.dmg" ;;
    *) printf 'Unknown DISTRIBUTION: %s\n' "$distribution" >&2; exit 1 ;;
esac
image="${1:-$default_image}"
if [[ "$distribution" == release ]]; then
    codesign --verify --strict "$image"
    xcrun stapler validate "$image"
    spctl --assess --type open --context context:primary-signature --verbose=2 "$image"
fi
mount="$(mktemp -d "${TMPDIR:-/tmp}/floatlyrics-verify.XXXXXX")"
attached=0
cleanup() {
    if [[ "$attached" == 1 ]]; then hdiutil detach "$mount" -quiet || true; fi
    rmdir "$mount" || true
}
trap cleanup EXIT
hdiutil attach -readonly -nobrowse -mountpoint "$mount" "$image"
attached=1
app="$mount/Float Lyrics.app"
test -x "$app/Contents/MacOS/FloatLyrics"
test -f "$app/Contents/Resources/AppIcon.icns"
cmp "$mount/.VolumeIcon.icns" "$app/Contents/Resources/AppIcon.icns"
test "$(GetFileInfo -aC "$mount")" = 1
test -f "$app/Contents/Resources/LICENSE.txt"
test -f "$app/Contents/Resources/KeyboardShortcuts-LICENSE.txt"
test -f "$app/Contents/Resources/KeyboardShortcuts_KeyboardShortcuts.bundle/Contents/Resources/en.lproj/Localizable.strings"
test "$(readlink "$mount/Applications")" = /Applications
test -f "$mount/Read me.txt"
test -f "$mount/License.txt"
plutil -lint "$app/Contents/Info.plist"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$app/Contents/Info.plist")" = "Float Lyrics"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "$version"
lipo "$app/Contents/MacOS/FloatLyrics" -verify_arch arm64 x86_64
codesign --verify --deep --strict "$app"
if [[ "$distribution" == release ]]; then
    signature="$(codesign -dvvv "$app" 2>&1)"
    [[ "$signature" == *"Authority=Developer ID Application: "* ]]
    xcrun stapler validate "$app"
    syspolicy_check distribution "$app"
    printf 'Notarized installer, matching volume logo, universal executable and Gatekeeper acceptance verified.\n'
else
    printf 'Preview contents, matching volume logo, universal executable and app signature verified.\n'
    printf 'This preview is not verified for distribution by Gatekeeper.\n'
fi

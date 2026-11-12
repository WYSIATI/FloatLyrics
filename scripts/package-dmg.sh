#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

distribution="${DISTRIBUTION:-release}"
case "$distribution" in
    release)
        if [[ "${SIGNING_IDENTITY:-}" != "Developer ID Application: "* || -z "${NOTARY_PROFILE:-}" ]]; then
            printf '%s\n' 'Release packaging requires SIGNING_IDENTITY="Developer ID Application: …" and NOTARY_PROFILE.' \
                'See docs/RELEASING.md for setup. For an unnotarized test installer, explicitly set DISTRIBUTION=preview.' >&2
            exit 1
        fi
        output_dir="$PWD/dist"
        suffix=""
        ;;
    preview)
        export SIGNING_IDENTITY="-"
        output_dir="$PWD/dist/preview"
        suffix="-preview"
        printf '%s\n' 'Building an unnotarized preview. macOS will require Open Anyway for downloaded copies.' >&2
        ;;
    *) printf 'Unknown DISTRIBUTION: %s (use release or preview)\n' "$distribution" >&2; exit 1 ;;
esac

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then bash scripts/build-app.sh; fi
app="$PWD/build/Float Lyrics.app"
codesign --verify --deep --strict "$app"
if [[ "$distribution" == release ]]; then
    # Also inspect a reused app: SKIP_BUILD must not allow ad-hoc code into a release.
    signature="$(codesign -dvvv "$app" 2>&1)"
    if [[ "$signature" != *"Authority=Developer ID Application: "* ]]; then
        printf '%s\n' 'The app must be signed with Developer ID Application before release packaging.' >&2
        exit 1
    fi
    ditto -c -k --keepParent "$app" build/FloatLyrics-notarize.zip
    bash scripts/notarize.sh build/FloatLyrics-notarize.zip "$app"
fi
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
mkdir -p "$output_dir"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/floatlyrics-dmg.XXXXXX")"
staging="$workspace/contents"
mount="$workspace/mount"
attached=0
cleanup() {
    if [[ "$attached" == 1 ]]; then hdiutil detach "$mount" -quiet || return; fi
    rm -rf "$workspace"
}
trap cleanup EXIT
mkdir -p "$staging" "$mount"
ditto "$app" "$staging/Float Lyrics.app"
ln -s /Applications "$staging/Applications"
cp Resources/Install.txt "$staging/Read me.txt"
cp LICENSE "$staging/License.txt"
cp "$app/Contents/Resources/AppIcon.icns" "$staging/.VolumeIcon.icns"
if [[ "$distribution" == preview ]]; then
    cat Resources/Preview.txt >> "$staging/Read me.txt"
fi

output="$output_dir/Float-Lyrics-$version$suffix.dmg"
# hdiutil does not preserve the staging folder's custom-icon flag on the volume
# root. Set it on a writable image before compressing the final installer.
hdiutil create -volname "Float Lyrics" -fs HFS+ -srcfolder "$staging" -format UDRW "$workspace/installer.dmg"
hdiutil attach -nobrowse -mountpoint "$mount" "$workspace/installer.dmg"
attached=1
SetFile -a C "$mount"
hdiutil detach "$mount" -quiet
attached=0
hdiutil convert "$workspace/installer.dmg" -format UDZO -ov -o "$output"
swift scripts/set-dmg-icon.swift "$app/Contents/Resources/AppIcon.icns" "$output"
if [[ "$distribution" == release ]]; then
    dmg_sign_args=(--sign "$SIGNING_IDENTITY" --timestamp)
    if [[ -n "${SIGNING_KEYCHAIN:-}" ]]; then dmg_sign_args+=(--keychain "$SIGNING_KEYCHAIN"); fi
    codesign "${dmg_sign_args[@]}" "$output"
    bash scripts/notarize.sh "$output" "$output"
fi
for attempt in 1 2 3; do
    if verification="$(hdiutil verify "$output" 2>&1)"; then
        printf '%s\n' "$verification"
        break
    fi
    printf '%s\n' "$verification" >&2
    # Fresh images can briefly be held by macOS background scanning on hosted runners.
    if [[ "$verification" != *"Resource temporarily unavailable"* && "$verification" != *"Resource busy"* ]] || [[ "$attempt" == 3 ]]; then
        exit 1
    fi
    sleep "$attempt"
done
DISTRIBUTION="$distribution" bash scripts/verify-dmg.sh "$output"
(
    cd "$output_dir"
    shasum -a 256 "Float-Lyrics-$version$suffix.dmg" > "Float-Lyrics-$version$suffix.dmg.sha256"
)
printf 'Packaged %s\n' "$output"
cp -p "$output" "$output_dir/Float-Lyrics.dmg"
# Keep existing public download links working.
cp -p "$output" "$output_dir/FloatLyrics.dmg"
# Remove obsolete installer archives when reusing an output directory.
rm -f "$output.zip" "$output.zip.sha256" "$output_dir/Float-Lyrics.dmg.zip" "$output_dir/Float-Lyrics.dmg.zip.sha256"
(
    cd "$output_dir"
    shasum -a 256 "Float-Lyrics-$version$suffix.dmg" Float-Lyrics.dmg FloatLyrics.dmg > SHA256SUMS.txt
)

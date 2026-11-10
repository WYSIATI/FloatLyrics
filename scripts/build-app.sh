#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

configuration="${CONFIGURATION:-release}"
architecture="${ARCHITECTURE:-universal}"
swift_args=(-c "$configuration")
if [[ "$architecture" == "universal" ]]; then
    swift_args+=(--arch arm64 --arch x86_64)
fi
swift build "${swift_args[@]}"
binary_dir="$(swift build "${swift_args[@]}" --show-bin-path)"
app="$PWD/build/Float Lyrics.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary_dir/FloatLyrics" "$app/Contents/MacOS/FloatLyrics"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp LICENSE "$app/Contents/Resources/LICENSE.txt"
cp NOTICE.md "$app/Contents/Resources/NOTICE.md"
swift scripts/make-icon.swift "$PWD/build"
iconutil -c icns build/AppIcon.iconset -o "$app/Contents/Resources/AppIcon.icns"
chmod +x "$app/Contents/MacOS/FloatLyrics"

identity="${SIGNING_IDENTITY:--}"
sign_args=(--force --options runtime --entitlements Resources/FloatLyrics.entitlements --sign "$identity")
if [[ "$identity" != "-" ]]; then sign_args+=(--timestamp); fi
codesign "${sign_args[@]}" "$app"
codesign --verify --deep --strict "$app"
printf 'Built %s (%s)\n' "$app" "$architecture"

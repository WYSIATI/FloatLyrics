#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

configuration="${CONFIGURATION:-release}"
architecture="${ARCHITECTURE:-universal}"
output_dir="$PWD/build"
entitlements=Resources/FloatLyrics.entitlements
# Use Xcode's resource-bundle lookup for both native and universal app bundles.
swift_args=(-c "$configuration" --build-system xcode)
case "${1:-}" in
    --app-store)
        output_dir="${2:-$PWD/build/app-store}"
        # This script has already changed to the repository root.
        [[ "$output_dir" == /* ]] || { echo "Pass the output directory as an absolute path." >&2; exit 1; }
        entitlements=Resources/FloatLyrics-AppStore.entitlements
        swift_args+=(--scratch-path "$PWD/build/swiftpm-app-store" -Xswiftc -DAPP_STORE)
        ;;
    "") ;;
    *) echo "Usage: $0 [--app-store [output-directory]]" >&2; exit 1 ;;
esac
if [[ "$architecture" == "universal" ]]; then
    swift_args+=(--arch arm64 --arch x86_64)
else
    swift_args+=(--arch "$(uname -m)")
fi
swift build "${swift_args[@]}"
binary_dir="$(swift build "${swift_args[@]}" --show-bin-path)"
app="$output_dir/Float Lyrics.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary_dir/FloatLyrics" "$app/Contents/MacOS/FloatLyrics"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp LICENSE "$app/Contents/Resources/LICENSE.txt"
cp NOTICE.md "$app/Contents/Resources/NOTICE.md"
cp Resources/ThirdPartyLicenses/KeyboardShortcuts.txt "$app/Contents/Resources/KeyboardShortcuts-LICENSE.txt"
ditto "$binary_dir/KeyboardShortcuts_KeyboardShortcuts.bundle" "$app/Contents/Resources/KeyboardShortcuts_KeyboardShortcuts.bundle"
if [[ "${1:-}" == --app-store ]]; then
    swift scripts/make-icon.swift "$output_dir" --asset-catalog
    minimum_os="$(plutil -extract LSMinimumSystemVersion raw Resources/Info.plist)"
    xcrun actool --app-icon AppIcon --platform macosx --target-device mac --minimum-deployment-target "$minimum_os" \
        --compile "$app/Contents/Resources" --output-partial-info-plist "$output_dir/IconInfo.plist" "$output_dir/Assets.xcassets"
    cp Resources/PrivacyInfo.xcprivacy "$app/Contents/Resources/"
    # SwiftPM's resource bundle carries the SDK and Xcode metadata for this exact build.
    python3 - "$app/Contents" "$output_dir/IconInfo.plist" <<'PY'
import plistlib
import sys
from pathlib import Path

contents = Path(sys.argv[1])
app_info = contents / "Info.plist"
resource_info = contents / "Resources/KeyboardShortcuts_KeyboardShortcuts.bundle/Contents/Info.plist"
app = plistlib.loads(app_info.read_bytes())
app.update(plistlib.loads(Path(sys.argv[2]).read_bytes()))
resources = plistlib.loads(resource_info.read_bytes())
for key in ("DTXcode", "DTXcodeBuild", "DTSDKName", "DTSDKBuild", "DTPlatformName",
            "DTPlatformVersion", "DTPlatformBuild", "DTCompiler", "BuildMachineOSBuild",
            "CFBundleSupportedPlatforms", "CFBundleDevelopmentRegion", "CFBundleInfoDictionaryVersion"):
    app[key] = resources[key]
app["LSApplicationCategoryType"] = "public.app-category.music"
app["NSAppleEventsUsageDescription"] = (
    "Float Lyrics reads the playing track and position from your music app. "
    "It sends the song title, artist, album and duration to LRCLIB to find lyrics."
)
app_info.write_bytes(plistlib.dumps(app))
# This localization-only bundle has no Mach-O executable.
resources.pop("CFBundleExecutable", None)
resource_info.write_bytes(plistlib.dumps(resources))
PY
else
    swift scripts/make-icon.swift "$output_dir"
    iconutil -c icns "$output_dir/AppIcon.iconset" -o "$app/Contents/Resources/AppIcon.icns"
fi
chmod +x "$app/Contents/MacOS/FloatLyrics"

identity="${SIGNING_IDENTITY:--}"
sign_args=(--force --options runtime --entitlements "$entitlements" --sign "$identity")
if [[ -n "${SIGNING_KEYCHAIN:-}" ]]; then sign_args+=(--keychain "$SIGNING_KEYCHAIN"); fi
if [[ "$identity" != "-" ]]; then sign_args+=(--timestamp); fi
codesign "${sign_args[@]}" "$app"
codesign --verify --deep --strict "$app"
printf 'Built %s (%s)\n' "$app" "$architecture"

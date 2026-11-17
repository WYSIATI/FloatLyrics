#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { echo "$*" >&2; exit 1; }
case "${STORE_APP_IDENTITY:-}" in
    "Apple Distribution: "*|"3rd Party Mac Developer Application: "*) ;;
    *) fail "Set STORE_APP_IDENTITY to your full Mac App Store app signing identity." ;;
esac
[[ "${STORE_INSTALLER_IDENTITY:-}" == "3rd Party Mac Developer Installer: "* ]] ||
    fail "Set STORE_INSTALLER_IDENTITY to your full Mac Installer Distribution identity."

# Installer identities are visible to the basic policy, not the codesigning policy.
identity_query=(security find-identity -v)
if [[ -n "${SIGNING_KEYCHAIN:-}" ]]; then identity_query+=("$SIGNING_KEYCHAIN"); fi
identities="$("${identity_query[@]}")"
app_hash="$(awk -F'"' -v name="$STORE_APP_IDENTITY" '$2 == name { split($1, parts, " "); print parts[2] }' <<< "$identities")"
[[ "$app_hash" =~ ^[0-9A-Fa-f]{40}$ ]] ||
    fail "Expected one valid app signing identity with its private key in the selected keychain."
[[ "$identities" == *"\"$STORE_INSTALLER_IDENTITY\""* ]] ||
    fail "Mac Installer Distribution certificate and private key unavailable in the selected keychain."
team_pattern='\(([A-Z0-9]{10})\)$'
[[ "$STORE_APP_IDENTITY" =~ $team_pattern ]] || fail "App signing identity is missing its team ID."
team="${BASH_REMATCH[1]}"
[[ "$STORE_INSTALLER_IDENTITY" == *"($team)" ]] || fail "App and installer identities must use the same team."

output="$PWD/dist/app-store"
mkdir -p "$output"
work="$(mktemp -d "$output/.package.XXXXXX")"
trap 'rm -rf "$work"' EXIT
app="$work/Float Lyrics.app"
entitlements="$work/FloatLyrics.entitlements"
cp Resources/FloatLyrics-AppStore.entitlements "$entitlements"

# The app only uses unrestricted macOS entitlements. Embed a profile when
# supplied, including when preparing the same build for TestFlight.
if [[ -n "${STORE_PROFILE:-}" ]]; then
    [[ -r "$STORE_PROFILE" ]] || fail "Cannot read STORE_PROFILE."
    security cms -D -i "$STORE_PROFILE" -o "$work/profile.plist"
    python3 - "$work/profile.plist" "$entitlements" "$team" "$app_hash" <<'PY'
import datetime
import hashlib
import plistlib
import sys
from pathlib import Path

profile_path, entitlements_path, team, fingerprint = sys.argv[1:]
profile = plistlib.loads(Path(profile_path).read_bytes())
allowed = profile["Entitlements"]
bundle = plistlib.loads(Path("Resources/Info.plist").read_bytes())["CFBundleIdentifier"]
app_id = f"{team}.{bundle}"
if allowed.get("com.apple.application-identifier") != app_id or team not in profile["TeamIdentifier"]:
    sys.exit("STORE_PROFILE must match this team and explicit macOS bundle ID.")
if ("OSX" not in profile.get("Platform", []) or "ProvisionedDevices" in profile or
        profile.get("ProvisionsAllDevices") or allowed.get("com.apple.security.get-task-allow") or
        profile["ExpirationDate"].replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc)):
    sys.exit("STORE_PROFILE must be a current Mac App Store distribution profile.")
if not any(hashlib.sha1(cert).hexdigest() == fingerprint.lower() for cert in profile["DeveloperCertificates"]):
    sys.exit("STORE_PROFILE does not authorize this app signing certificate.")
path = Path(entitlements_path)
signed = plistlib.loads(path.read_bytes())
signed["com.apple.application-identifier"] = app_id
signed["com.apple.developer.team-identifier"] = team
if allowed.get("beta-reports-active"):
    signed["beta-reports-active"] = True
path.write_bytes(plistlib.dumps(signed))
PY
fi

CONFIGURATION=release ARCHITECTURE=universal SIGNING_IDENTITY=- bash scripts/build-app.sh --app-store "$work"
if [[ -n "${STORE_PROFILE:-}" ]]; then cp "$STORE_PROFILE" "$app/Contents/embedded.provisionprofile"; fi
app_args=(--force --options runtime --entitlements "$entitlements" --sign "$app_hash")
package_args=(--sign "$STORE_INSTALLER_IDENTITY")
if [[ -n "${SIGNING_KEYCHAIN:-}" ]]; then
    app_args+=(--keychain "$SIGNING_KEYCHAIN")
    package_args+=(--keychain "$SIGNING_KEYCHAIN")
fi
codesign "${app_args[@]}" "$app"
codesign --verify --deep --strict "$app"
for arch in arm64 x86_64; do
    lipo "$app/Contents/MacOS/FloatLyrics" -verify_arch "$arch"
done

info="$app/Contents/Info.plist"
version="$(plutil -extract CFBundleShortVersionString raw "$info")"
build="$(plutil -extract CFBundleVersion raw "$info")"
file="Float-Lyrics-$version-$build.pkg"
productbuild "${package_args[@]}" --component "$app" /Applications "$work/$file"
pkgutil --check-signature "$work/$file"
mv -f "$work/$file" "$output/$file"
printf 'Signed Mac App Store package: %s/%s\n' "$output" "$file"

#!/bin/bash
set -euo pipefail

image="${1:?Usage: archive-dmg.sh installer.dmg}"
image="$(cd "$(dirname "$image")" && pwd)/$(basename "$image")"
filename="$(basename "$image")"
archive="$image.zip"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/floatlyrics-download.XXXXXX")"
trap 'rm -rf "$workspace"' EXIT

# A direct HTTP download cannot carry the Finder icon's resource fork. Keep it
# inside an AppleDouble ZIP entry that macOS restores when expanding the ZIP.
test "$(GetFileInfo -aC "$image")" = 1
xattr -p com.apple.ResourceFork "$image" > "$workspace/source-icon"
test -s "$workspace/source-icon"
(
    cd "$(dirname "$image")"
    ditto -c -k --rsrc --extattr --sequesterRsrc "$filename" "$workspace/download.zip"
)
ditto -x -k --rsrc --extattr "$workspace/download.zip" "$workspace/restored"
restored="$workspace/restored/$filename"
cmp "$image" "$restored"
test "$(GetFileInfo -aC "$restored")" = 1
for attribute in com.apple.FinderInfo com.apple.ResourceFork; do
    xattr -p "$attribute" "$image" > "$workspace/source-attribute"
    xattr -p "$attribute" "$restored" > "$workspace/restored-attribute"
    cmp "$workspace/source-attribute" "$workspace/restored-attribute"
done
mv "$workspace/download.zip" "$archive"
(
    cd "$(dirname "$archive")"
    shasum -a 256 "$(basename "$archive")" > "$(basename "$archive").sha256"
)
printf 'Archived %s; extracted DMG bytes and Finder logo metadata match.\n' "$archive"

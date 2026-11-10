#!/bin/bash
set -euo pipefail

archive="${1:?Usage: notarize.sh archive app-or-dmg-to-staple}"
target="${2:?Usage: notarize.sh archive app-or-dmg-to-staple}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to your notarytool keychain profile}"
result="$(mktemp "${TMPDIR:-/tmp}/floatlyrics-notary.XXXXXX")"
trap 'rm -f "$result"' EXIT

if ! xcrun notarytool submit "$archive" --keychain-profile "$NOTARY_PROFILE" \
    --wait --timeout 20m --output-format json > "$result"; then
    cat "$result" >&2
    printf 'Notarization submission failed: %s\n' "$archive" >&2
    exit 1
fi
# A completed request can still be Invalid. Only Accepted permits distribution.
status="$(plutil -extract status raw -o - "$result")"
if [[ "$status" != Accepted ]]; then
    cat "$result" >&2
    submission_id="$(plutil -extract id raw -o - "$result")"
    printf 'Notarization was %s. Fetch the report with:\nxcrun notarytool log %s --keychain-profile %q\n' \
        "$status" "$submission_id" "$NOTARY_PROFILE" >&2
    exit 1
fi
xcrun stapler staple "$target"
xcrun stapler validate "$target"

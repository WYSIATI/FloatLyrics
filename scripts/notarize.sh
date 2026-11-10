#!/bin/bash
set -euo pipefail

archive="${1:?Usage: notarize.sh archive app-or-dmg-to-staple}"
target="${2:?Usage: notarize.sh archive app-or-dmg-to-staple}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to your notarytool keychain profile}"
credential_args=(--keychain-profile "$NOTARY_PROFILE")
if [[ -n "${NOTARY_KEYCHAIN:-}" ]]; then credential_args+=(--keychain "$NOTARY_KEYCHAIN"); fi
result="$(mktemp "${TMPDIR:-/tmp}/floatlyrics-notary.XXXXXX")"
trap 'rm -f "$result"' EXIT

if ! xcrun notarytool submit "$archive" "${credential_args[@]}" \
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
    printf 'Notarization was %s. Fetch the report with:\nxcrun notarytool log %q' \
        "$status" "$submission_id" >&2
    printf ' %q' "${credential_args[@]}" >&2
    printf '\n' >&2
    exit 1
fi
xcrun stapler staple "$target"
xcrun stapler validate "$target"

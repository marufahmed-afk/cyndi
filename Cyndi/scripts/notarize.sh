#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

APP_NAME="Cyndi"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
ZIP="$DIST/$APP_NAME.zip"
PROFILE="${NOTARY_PROFILE:-cyndi-notary}"

[[ -d "$APP" ]] || { echo "!! $APP not found — run scripts/package.sh first"; exit 1; }

if ! codesign --verify --strict "$APP" >/dev/null 2>&1; then
  echo "!! $APP is not validly signed. Sign it first (needs a Developer ID cert)."
  exit 1
fi

echo "==> notarization credential check (profile: $PROFILE)"
if ! xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
  cat <<EOF
!! No stored notarization credential named "$PROFILE".
   Store one first (choose ONE):

   # App Store Connect API key (recommended)
   xcrun notarytool store-credentials "$PROFILE" \\
     --key /path/to/AuthKey_XXXX.p8 --key-id KEYID --issuer ISSUER-UUID

   # or Apple ID + app-specific password
   xcrun notarytool store-credentials "$PROFILE" \\
     --apple-id you@example.com --team-id TEAMID --password app-specific-pw
EOF
  exit 1
fi

echo "==> zipping for submission"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> submitting to notary service (waits for result)"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

echo "==> stapling ticket"
xcrun stapler staple "$APP"

echo "==> verifying"
xcrun stapler validate "$APP"
spctl -a -vv "$APP"

rm -f "$ZIP"
echo "==> notarized + stapled: $APP"

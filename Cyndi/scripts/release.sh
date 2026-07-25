#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

APP_NAME="Cyndi"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
DMG="$DIST/$APP_NAME.dmg"
REPO="marufahmed-afk/cyndi"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(defaults read "$APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 0.1.0)"
fi
VERSION="${VERSION#v}"
TAG="v$VERSION"

[[ -d "$APP" ]] || { echo "!! $APP not found — run package.sh + notarize.sh first"; exit 1; }

if ! xcrun stapler validate "$APP" >/dev/null 2>&1; then
  echo "!! $APP has no stapled notarization ticket. Run scripts/notarize.sh first."
  echo "   (Shipping an un-notarized dmg means Gatekeeper blocks it on other Macs.)"
  exit 1
fi

echo "==> building dmg"
rm -f "$DMG"
STAGE="$(mktemp -d)/dmg"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
echo "    -> $DMG"

SHA="$(shasum -a 256 "$DMG" | awk '{print $1}')"

echo "==> creating GitHub release $TAG on $REPO"
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  gh release upload "$TAG" "$DMG" --repo "$REPO" --clobber
else
  gh release create "$TAG" "$DMG" --repo "$REPO" \
    --title "$APP_NAME $VERSION" \
    --notes "Cyndi $VERSION — install via \`brew install --cask marufahmed-afk/cyndi/cyndi\`"
fi

cat <<EOF

==> released: https://github.com/$REPO/releases/tag/$TAG

Update the cask (Casks/cyndi.rb in marufahmed-afk/homebrew-cyndi):
  version "$VERSION"
  sha256 "$SHA"
EOF

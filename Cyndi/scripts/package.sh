#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/.." && pwd)"

APP_NAME="Cyndi"
BUNDLE_ID="com.marufahmed.cyndi"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RES_DIR="$CONTENTS/Resources"
BUILD_DIR="$ROOT/.build/release"
RES_BUNDLE="Cyndi_Cyndi.bundle"
ASSETS="$REPO_ROOT/assets"
PLIST_TEMPLATE="$ROOT/packaging/Info.plist.template"
ENTITLEMENTS="$ROOT/packaging/Cyndi.entitlements"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(git -C "$ROOT" describe --tags --abbrev=0 2>/dev/null || echo 0.1.0)"
fi
VERSION="${VERSION#v}"
BUILD_NUMBER="$(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || echo 1)"

SIGN_ID="${CODESIGN_IDENTITY:-}"
if [[ -z "$SIGN_ID" ]]; then
  SIGN_ID="$(security find-identity -v -p codesigning 2>/dev/null \
    | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)"/\1/')"
fi

echo "==> Cyndi packaging"
echo "    version:  $VERSION ($BUILD_NUMBER)"
if [[ -n "$SIGN_ID" ]]; then
  echo "    identity: $SIGN_ID"
else
  echo "    identity: (none found — will assemble UNSIGNED)"
fi

echo "==> swift build -c release"
( cd "$ROOT" && swift build -c release )

BIN="$BUILD_DIR/$APP_NAME"
[[ -f "$BIN" ]] || { echo "!! binary not found at $BIN"; exit 1; }
[[ -d "$BUILD_DIR/$RES_BUNDLE" ]] || { echo "!! resource bundle $RES_BUNDLE not found"; exit 1; }

echo "==> assembling $APP"
rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RES_DIR"

cp "$BIN" "$MACOS_DIR/$APP_NAME"
cp -R "$BUILD_DIR/$RES_BUNDLE" "$RES_DIR/$RES_BUNDLE"

echo "==> building icon"
if [[ -d "$ASSETS" ]]; then
  ICONSET="$(mktemp -d)/Cyndi.iconset"
  mkdir -p "$ICONSET"
  declare -a map=(
    "icon_16x16.png:icon_16x16.png"
    "icon_16x16-2x.png:icon_16x16@2x.png"
    "icon_32x32.png:icon_32x32.png"
    "icon_32x32-2x.png:icon_32x32@2x.png"
    "icon_128x128.png:icon_128x128.png"
    "icon_128x128-2x.png:icon_128x128@2x.png"
    "icon_256x256.png:icon_256x256.png"
    "icon_256x256-2x.png:icon_256x256@2x.png"
    "icon_512x512.png:icon_512x512.png"
    "icon_512x512-2x.png:icon_512x512@2x.png"
  )
  for pair in "${map[@]}"; do
    src="$ASSETS/${pair%%:*}"
    dst="$ICONSET/${pair##*:}"
    [[ -f "$src" ]] && cp "$src" "$dst"
  done
  iconutil -c icns "$ICONSET" -o "$RES_DIR/$APP_NAME.icns"
  echo "    -> $RES_DIR/$APP_NAME.icns"
else
  echo "    (no assets/ dir; skipping icon)"
fi

echo "==> writing Info.plist"
sed -e "s/__SHORT_VERSION__/$VERSION/g" \
    -e "s/__BUILD_VERSION__/$BUILD_NUMBER/g" \
    "$PLIST_TEMPLATE" > "$CONTENTS/Info.plist"

printf 'APPL????' > "$CONTENTS/PkgInfo"

if [[ -n "$SIGN_ID" ]]; then
  echo "==> codesign"
  codesign --force --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SIGN_ID" \
    "$APP"

  echo "==> verify"
  codesign --verify --deep --strict --verbose=2 "$APP"
  echo "-- spctl (expect 'rejected' until notarized) --"
  spctl -a -vv "$APP" || true
else
  echo "==> skipping codesign (no Developer ID identity)"
  echo "   create one, then: CODESIGN_IDENTITY='Developer ID Application: … (TEAMID)' $0"
fi

echo "==> done: $APP"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
BASE_URL="https://www.experiments.cwandt.com/crowsflight"
ARCHIVE="build/ota/Crowsflight.xcarchive"
IPA_SRC=$(ls build/ota/export/*.ipa | head -1)
DIST="dist/crowsflight"
BID="com.cwandt.crowsflight"

rm -rf "$DIST"; mkdir -p "$DIST"
cp "$IPA_SRC" "$DIST/Crowsflight.ipa"

# Version from the archived app Info.plist (single source of truth)
APP=$(ls -d "$ARCHIVE"/Products/Applications/*.app | head -1)
APP_PLIST="$APP/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PLIST")
echo "Packaging Crowsflight v$VERSION ($BUILD)"

# Pick the largest AppIcon PNG from the built app bundle
ICON=$(ls -S "$APP/"AppIcon*.png 2>/dev/null | head -1 || true)
[ -z "${ICON:-}" ] && ICON=$(ls -S "$APP/"*.png 2>/dev/null | head -1)
echo "Icon source: $ICON"
sips -s format png -z 512 512 "$ICON" --out "$DIST/icon-512.png" >/dev/null
sips -s format png -z 57  57  "$ICON" --out "$DIST/icon-57.png"  >/dev/null

# manifest.plist (itms-services)
cat > "$DIST/manifest.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>items</key><array><dict>
  <key>assets</key><array>
    <dict><key>kind</key><string>software-package</string><key>url</key><string>$BASE_URL/Crowsflight.ipa</string></dict>
    <dict><key>kind</key><string>display-image</string><key>url</key><string>$BASE_URL/icon-57.png</string></dict>
    <dict><key>kind</key><string>full-size-image</string><key>url</key><string>$BASE_URL/icon-512.png</string></dict>
  </array>
  <key>metadata</key><dict>
    <key>bundle-identifier</key><string>$BID</string>
    <key>bundle-version</key><string>$VERSION</string>
    <key>kind</key><string>software</string>
    <key>title</key><string>Crowsflight</string>
  </dict>
</dict></array></dict></plist>
EOF

# Landing page + static assets
sed "s/__VERSION__/$VERSION/g" scripts/ota/site/index.html.tmpl > "$DIST/index.html"
cp scripts/ota/site/.htaccess "$DIST/.htaccess"
cp scripts/ota/site/favicon.ico scripts/ota/site/favicon-16x16.png \
   scripts/ota/site/favicon-32x32.png scripts/ota/site/apple-touch-icon.png "$DIST/"

echo "PACKAGED $DIST:"; ls -la "$DIST"

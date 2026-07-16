#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
ARCHIVE="build/ota/Crowsflight.xcarchive"
OUT="build/ota/export"
rm -rf "$OUT"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$OUT" \
  -exportOptionsPlist scripts/ota/ExportOptions.plist \
  -allowProvisioningUpdates
echo "EXPORTED:"; ls -la "$OUT"

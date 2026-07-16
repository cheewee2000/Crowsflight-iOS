#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
ARCHIVE="build/ota/Crowsflight.xcarchive"
rm -rf "$ARCHIVE"
xcodebuild \
  -project Crowsflight.xcodeproj \
  -scheme Crowsflight \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  archive
echo "ARCHIVED: $ARCHIVE"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
REMOTE_HOST="cwandt@vps52023.dreamhostps.com"
REMOTE_BASE="experiments.cwandt.com"   # DreamHost docroot dir for www.experiments.cwandt.com
DIST="dist/crowsflight/"
ssh "$REMOTE_HOST" "mkdir -p ~/$REMOTE_BASE/crowsflight"
rsync -avz --delete "$DIST" "$REMOTE_HOST:~/$REMOTE_BASE/crowsflight/"
echo "DEPLOYED to ~/$REMOTE_BASE/crowsflight/"

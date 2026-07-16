# Crowsflight Ad-hoc OTA Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a signed ad-hoc `.ipa` of Crowsflight and host it, with an `itms-services` OTA install page, at `https://www.experiments.cwandt.com/crowsflight/` so registered CW&T devices can install it.

**Architecture:** Four scripted stages (`archive → export → package → deploy`) under `scripts/ota/`, preceded by a one-time human signing setup in Xcode. Build artifacts and the landing page are assembled into `dist/crowsflight/` and rsynced to the DreamHost VPS. "Tests" here are concrete verification commands (`codesign`, `plutil`, `curl -I`) plus a final real-device install.

**Tech Stack:** Xcode 26.6 / `xcodebuild`, macOS `security`/`codesign`/`plutil`, bash, rsync/ssh to DreamHost, Apache `.htaccess`.

## Global Constraints

- Apple team: `L6DVQR8JB9` (CW&T org). Export method: `release-testing` (ad-hoc).
- Main app bundle id: `com.cwandt.crowsflight`. Version source of truth: `MARKETING_VERSION` (currently `1.9.0`) read from the built archive's `Info.plist`.
- Build source: `widget` branch **as-is**. If archive fails on the widget/watch target, STOP and report — do not exclude it.
- All hosted OTA URLs must be HTTPS with a valid cert and **no redirect** on the manifest URL. Host under `www.experiments.cwandt.com` (apex 301s → www).
- VPS: `cwandt@vps52023.dreamhostps.com`, site dir `~/experiments.cwandt.com/` (confirm docroot on first deploy). Use `python3` on VPS.
- CW&T conventions: landing page shows a **visible version number**, bumped every release; **favicon** = solid color circle (diameter 50% of width, centered, transparent bg), project color `#000000` (Crowsflight = crow/black); create a **GitHub repo** for the site.
- Ad-hoc installs only on devices whose UDID is registered in the profile.

---

### Task 1: Signing prerequisites (Stage 0 — interactive Xcode, human-driven)

**Files:** none (portal/keychain state only).

**Interfaces:**
- Produces: an `Apple Distribution` codesigning identity for team `L6DVQR8JB9` in the login keychain; ad-hoc provisioning profiles covering `com.cwandt.crowsflight`, `com.cwandt.crowsflight.share`, `com.cwandt.crowsflight.CrowsflightWidget-` including the known device UDID.

- [ ] **Step 1: Confirm the known device's real UDID**

Plug the iPhone into this Mac, then run:
```bash
xcrun xctrace list devices 2>&1 | grep -v Simulator
```
Expected: a line ending in a 25- or 40-char UDID for the physical iPhone. Record it. (A simulator id will NOT work for ad-hoc.)

- [ ] **Step 2: Confirm org signing access**

In Xcode → Settings → Accounts, confirm an account is listed under team **CW&T (`L6DVQR8JB9`)** with a role that can create certificates (Admin / App Manager / or "Agent"). If only personal teams appear, stop and resolve org membership before continuing.

- [ ] **Step 3: Register the device + create distribution signing**

In Xcode → Window → Devices and Simulators, confirm the plugged-in device is "registered for development"; then in the Crowsflight target's Signing & Capabilities, with team set to `L6DVQR8JB9` and "Automatically manage signing" on, let Xcode create the Apple Distribution certificate. Register the UDID in the org's device list (Xcode does this when the device is connected + selected, or via the Developer portal).

- [ ] **Step 4: Verify the distribution identity exists**

Run:
```bash
security find-identity -v -p codesigning | grep -i "Apple Distribution"
```
Expected: at least one `Apple Distribution: ... (L6DVQR8JB9)` identity. If absent, Stage 0 is not complete — do not proceed.

- [ ] **Step 5: Verify ad-hoc profiles present**

Run:
```bash
ls -1 ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | while read p; do
  echo "== $p =="; security cms -D -i "$p" 2>/dev/null | plutil -extract Name raw - 2>/dev/null
done
```
Expected: profiles whose names/app-ids map to the three bundle ids. (Xcode may generate these lazily during the first archive/export in Task 2; if missing here, re-check after Task 2 Step 3.)

No commit (no repo files changed).

---

### Task 2: Build scripts — archive & ad-hoc export

**Files:**
- Create: `scripts/ota/ExportOptions.plist`
- Create: `scripts/ota/archive.sh`
- Create: `scripts/ota/export.sh`

**Interfaces:**
- Produces: `build/ota/Crowsflight.xcarchive` (from `archive.sh`); `build/ota/export/Crowsflight.ipa` (from `export.sh`). Later tasks read the version from the archive `Info.plist` and copy the `.ipa`.

- [ ] **Step 1: Write `scripts/ota/ExportOptions.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>release-testing</string>
    <key>teamID</key>
    <string>L6DVQR8JB9</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
```

- [ ] **Step 2: Write `scripts/ota/archive.sh`**

```bash
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
  archive
echo "ARCHIVED: $ARCHIVE"
```

- [ ] **Step 3: Write `scripts/ota/export.sh`**

```bash
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
```

- [ ] **Step 4: Make executable and run archive**

```bash
chmod +x scripts/ota/archive.sh scripts/ota/export.sh
./scripts/ota/archive.sh
```
Expected: ends with `ARCHIVED: build/ota/Crowsflight.xcarchive` and `** ARCHIVE SUCCEEDED **`.
**If it fails on the widget/watch target → STOP, report the exact error (per plan constraint).**

- [ ] **Step 5: Run export and verify the IPA is ad-hoc signed**

```bash
./scripts/ota/export.sh
IPA=$(ls build/ota/export/*.ipa | head -1)
echo "IPA: $IPA"
# unzip and inspect the embedded profile + signature
WORK=$(mktemp -d); unzip -q "$IPA" -d "$WORK"
codesign -dv "$WORK/Payload/"*.app 2>&1 | grep -iE "Authority|TeamIdentifier"
security cms -D -i "$WORK/Payload/"*.app/embedded.mobileprovision 2>/dev/null | plutil -extract ProvisionedDevices raw - 2>/dev/null | head
rm -rf "$WORK"
```
Expected: `TeamIdentifier=L6DVQR8JB9`, an `Apple Distribution` authority, and the known UDID listed under `ProvisionedDevices`.

- [ ] **Step 6: Commit**

```bash
git add scripts/ota/ExportOptions.plist scripts/ota/archive.sh scripts/ota/export.sh
git commit -m "Add ad-hoc archive + export scripts for OTA distribution"
```

---

### Task 3: Landing page + favicon

**Files:**
- Create: `scripts/ota/site/index.html.tmpl`
- Create: `scripts/ota/site/make_favicon.sh`
- Create: `scripts/ota/site/.htaccess`

**Interfaces:**
- Consumes: nothing from prior tasks (template uses `__VERSION__` and `__IPA_NAME__` placeholders filled by Task 4's `package_ota.sh`).
- Produces: an HTML template + favicon generator + Apache MIME config that Task 4 copies into `dist/crowsflight/`.

- [ ] **Step 1: Write `scripts/ota/site/index.html.tmpl`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Crowsflight — Test Build</title>
<link rel="icon" href="favicon.ico" sizes="any">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<style>
  :root { color-scheme: light dark; }
  body { font: 17px/1.5 -apple-system, system-ui, sans-serif; margin: 0;
         display: grid; place-items: center; min-height: 100vh;
         padding: 2rem; text-align: center; }
  .card { max-width: 24rem; }
  img.icon { width: 96px; height: 96px; border-radius: 22px; }
  h1 { margin: 1rem 0 .25rem; }
  .ver { opacity: .6; font-size: .9rem; margin-bottom: 1.5rem; }
  a.install { display: inline-block; background: #000; color: #fff;
              text-decoration: none; padding: .8rem 1.6rem; border-radius: 999px;
              font-weight: 600; }
  @media (prefers-color-scheme: dark) { a.install { background:#fff; color:#000; } }
  .note { font-size: .8rem; opacity: .6; margin-top: 2rem; }
  footer { position: fixed; bottom: .6rem; right: .8rem; font-size: .7rem; opacity: .4; }
</style>
</head>
<body>
  <div class="card">
    <img class="icon" src="icon-512.png" alt="Crowsflight">
    <h1>Crowsflight</h1>
    <div class="ver">Test build v__VERSION__</div>
    <a class="install" href="itms-services://?action=download-manifest&url=https://www.experiments.cwandt.com/crowsflight/manifest.plist">Install on iPhone</a>
    <p class="note">Open this page in <b>Safari on your iPhone</b>, then tap Install.
    Only registered devices can install — if it doesn't work, send Che-Wei your device UDID to be added.
    After installing, if iOS asks, trust the developer under
    Settings → General → VPN &amp; Device Management.</p>
  </div>
  <footer>v__VERSION__</footer>
</body>
</html>
```

- [ ] **Step 2: Write `scripts/ota/site/.htaccess`**

```apache
AddType application/octet-stream .ipa
AddType text/xml .plist
```

- [ ] **Step 3: Write `scripts/ota/site/make_favicon.sh`** (solid black circle, CW&T convention)

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
COLOR="#000000"
gen() { # size outfile
  local s=$1 out=$2 r=$(( $1 / 4 )) c=$(( $1 / 2 ))
  /usr/bin/python3 - "$s" "$r" "$c" "$out" "$COLOR" <<'PY'
import sys, struct, zlib
s,r,c=int(sys.argv[1]),int(sys.argv[2]),int(sys.argv[3]); out=sys.argv[4]
col=sys.argv[5].lstrip('#'); R,G,B=int(col[0:2],16),int(col[2:4],16),int(col[4:6],16)
raw=bytearray()
for y in range(s):
    raw.append(0)
    for x in range(s):
        inside=(x-c+0.5)**2+(y-c+0.5)**2 <= r*r
        raw += bytes((R,G,B,255)) if inside else bytes((0,0,0,0))
def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
png=b'\x89PNG\r\n\x1a\n'
png+=chunk(b'IHDR',struct.pack('>IIBBBBB',s,s,8,6,0,0,0))
png+=chunk(b'IDAT',zlib.compress(bytes(raw),9))
png+=chunk(b'IEND',b'')
open(out,'wb').write(png)
PY
}
gen 16  favicon-16x16.png
gen 32  favicon-32x32.png
gen 180 apple-touch-icon.png
# favicon.ico = 32px PNG wrapped in ICO container
/usr/bin/python3 - <<'PY'
import struct
png=open('favicon-32x32.png','rb').read()
ico=struct.pack('<HHH',0,1,1)+struct.pack('<BBBBHHII',32,32,0,0,1,32,len(png),22)
open('favicon.ico','wb').write(ico+png)
PY
echo "favicon assets generated"
```

- [ ] **Step 4: Generate and verify favicon**

```bash
chmod +x scripts/ota/site/make_favicon.sh
./scripts/ota/site/make_favicon.sh
file scripts/ota/site/favicon-32x32.png scripts/ota/site/favicon.ico
```
Expected: `favicon-32x32.png` reported as `PNG image data, 32 x 32`; `favicon.ico` as `MS Windows icon`.

- [ ] **Step 5: Commit**

```bash
git add scripts/ota/site/
git commit -m "Add OTA landing page template, favicon generator, and MIME config"
```

---

### Task 4: OTA packaging script

**Files:**
- Create: `scripts/ota/package_ota.sh`

**Interfaces:**
- Consumes: `build/ota/Crowsflight.xcarchive` and `build/ota/export/*.ipa` (Task 2); `scripts/ota/site/*` (Task 3).
- Produces: `dist/crowsflight/` containing `Crowsflight.ipa`, `manifest.plist`, `icon-57.png`, `icon-512.png`, `index.html`, `.htaccess`, and favicon assets.

- [ ] **Step 1: Write `scripts/ota/package_ota.sh`**

```bash
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

# Version from the archived app Info.plist
APP_PLIST=$(ls -d "$ARCHIVE"/Products/Applications/*.app | head -1)/Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PLIST")
echo "Packaging Crowsflight v$VERSION ($BUILD)"

# Extract a large icon from the built app; fall back to biggest AppIcon png
ICON=$(ls -S "$APP_PLIST/../"AppIcon*.png 2>/dev/null | head -1 || true)
if [ -z "${ICON:-}" ]; then ICON=$(ls -S "$APP_PLIST/../"*.png 2>/dev/null | head -1); fi
sips -z 512 512 "$ICON" --out "$DIST/icon-512.png" >/dev/null
sips -z 57 57  "$ICON" --out "$DIST/icon-57.png"  >/dev/null

# manifest.plist
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
```

- [ ] **Step 2: Run it and validate the manifest**

```bash
chmod +x scripts/ota/package_ota.sh
./scripts/ota/package_ota.sh
plutil -lint dist/crowsflight/manifest.plist
file dist/crowsflight/icon-512.png dist/crowsflight/icon-57.png
grep -c 'Test build v' dist/crowsflight/index.html
```
Expected: `manifest.plist: OK`; both icons are PNG at 512/57; grep prints `1` (version substituted).

- [ ] **Step 3: Commit**

```bash
git add scripts/ota/package_ota.sh
git commit -m "Add OTA packaging script (ipa + manifest + icons + page)"
```

---

### Task 5: Deploy script

**Files:**
- Create: `scripts/ota/deploy.sh`

**Interfaces:**
- Consumes: `dist/crowsflight/` (Task 4).
- Produces: files live at `https://www.experiments.cwandt.com/crowsflight/`.

- [ ] **Step 1: Confirm the VPS docroot**

```bash
ssh cwandt@vps52023.dreamhostps.com 'ls -d ~/experiments.cwandt.com ~/www.experiments.cwandt.com 2>/dev/null'
```
Expected: at least one path prints. Use the one Apache serves for `www.experiments.cwandt.com` (confirm with the host if both exist). Record it as `REMOTE_DIR`.

- [ ] **Step 2: Write `scripts/ota/deploy.sh`** (set `REMOTE_BASE` to the confirmed path)

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
REMOTE_HOST="cwandt@vps52023.dreamhostps.com"
REMOTE_BASE="experiments.cwandt.com"   # confirmed docroot dir in Step 1
DIST="dist/crowsflight/"
ssh "$REMOTE_HOST" "mkdir -p ~/$REMOTE_BASE/crowsflight"
rsync -avz --delete "$DIST" "$REMOTE_HOST:~/$REMOTE_BASE/crowsflight/"
echo "DEPLOYED to ~/$REMOTE_BASE/crowsflight/"
```

- [ ] **Step 3: Deploy**

```bash
chmod +x scripts/ota/deploy.sh
./scripts/ota/deploy.sh
```
Expected: rsync lists the transferred files, ends with `DEPLOYED`.

- [ ] **Step 4: Verify all hosted assets over HTTPS (no redirect on manifest)**

```bash
B=https://www.experiments.cwandt.com/crowsflight
for f in index.html manifest.plist Crowsflight.ipa icon-512.png icon-57.png; do
  echo "== $f =="; curl -sS -o /dev/null -w "%{http_code} %{content_type} redirects=%{num_redirects}\n" "$B/$f"
done
```
Expected: every line `200 ...`, `manifest.plist` → `text/xml` with `redirects=0`, `Crowsflight.ipa` → `application/octet-stream`. If the manifest shows a redirect or wrong type, fix `.htaccess`/docroot before announcing.

- [ ] **Step 5: Commit**

```bash
git add scripts/ota/deploy.sh
git commit -m "Add VPS deploy script for OTA distribution"
```

---

### Task 6: Site repo + push

**Files:**
- Create: GitHub repo for the site (per CW&T convention).

**Interfaces:**
- Consumes: `scripts/ota/site/` + `dist/crowsflight/` output.
- Produces: a pushed repo `experiments-cwandt-com` (or the app-repo scripts already cover it — decide here).

- [ ] **Step 1: Decide repo shape**

The OTA build scripts live in the app repo (`Crowsflight-iOS`, already pushed). The **site** (landing page template + favicon generator) also lives there under `scripts/ota/site/`. Per CW&T "always create a GitHub repo for every website," create a thin dedicated site repo only if the page should be independently editable; otherwise record here that the app repo is the site's home. **Recommendation:** keep it in the app repo (single source, already versioned) and note it. Confirm with Che-Wei at execution.

- [ ] **Step 2: Ensure scripts are pushed**

```bash
cd "$(git rev-parse --show-toplevel)"
git push origin widget
```
Expected: push succeeds to `github.com/cheewee2000/Crowsflight-iOS`.

- [ ] **Step 3: (If standalone repo chosen) create and push it**

```bash
mkdir -p ~/experiments-cwandt-com/crowsflight
cp scripts/ota/site/index.html.tmpl scripts/ota/site/make_favicon.sh scripts/ota/site/.htaccess ~/experiments-cwandt-com/crowsflight/
cd ~/experiments-cwandt-com && git init -q && git add -A \
  && git commit -q -m "Crowsflight OTA landing page v1.9.0" \
  && gh repo create cwandt/experiments-cwandt-com --private --source=. --push
```
Expected: repo created and pushed (skip if Step 1 chose "app repo is home").

---

### Task 7: End-to-end device install (acceptance)

**Files:** none.

**Interfaces:**
- Consumes: the live page at `https://www.experiments.cwandt.com/crowsflight/`.

- [ ] **Step 1: Install from the live page**

On the registered iPhone, open `https://www.experiments.cwandt.com/crowsflight/` in Safari, tap **Install on iPhone**, confirm the install prompt.
Expected: Crowsflight icon appears on the home screen and installs to 100%.

- [ ] **Step 2: Handle trust prompt if shown**

If the app shows "Untrusted Developer" on first launch, go Settings → General → VPN & Device Management → trust the CW&T developer, then relaunch. If this prompt appears, update `index.html.tmpl` copy to keep the trust instructions (already present) and re-deploy.

- [ ] **Step 3: Launch and smoke-test**

Open the app; confirm it launches to the compass/map screen without crashing.
Expected: app runs. This is the acceptance criterion — the task is done only when the app installs and launches from the hosted page.

- [ ] **Step 4: Announce to team**

Share `https://www.experiments.cwandt.com/crowsflight/` with the note that new testers must send their UDID first.

---

## Self-Review

- **Spec coverage:** Stage 0 → Task 1; Stages 1–2 → Task 2; Stage 3 (page/favicon) → Task 3; Stage 3 (manifest/package) → Task 4; Stage 4 (deploy) → Task 5; repo convention → Task 6; end-to-end verification → Task 7. All spec stages covered.
- **Placeholder scan:** `__VERSION__`/`__IPA_NAME__` are intentional template tokens filled by `package_ota.sh`; `REMOTE_BASE` is confirmed in Task 5 Step 1. No unresolved TODOs.
- **Type/name consistency:** artifact paths consistent across tasks (`build/ota/Crowsflight.xcarchive`, `build/ota/export/*.ipa`, `dist/crowsflight/`); bundle id `com.cwandt.crowsflight` and version-from-`Info.plist` used consistently in manifest + page.

## Open items (resolve at execution)

- Real device UDID (Task 1 Step 1) — the human provides the physical iPhone.
- Org signing role for `cwwang@gmail.com` on `L6DVQR8JB9` (Task 1 Step 2) — may need an org invite before Task 2 can produce a distribution-signed IPA.
- VPS docroot for `www.experiments.cwandt.com` (Task 5 Step 1).
- Repo shape decision (Task 6 Step 1).

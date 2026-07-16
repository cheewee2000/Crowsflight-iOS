# Crowsflight — Ad-hoc OTA Distribution to experiments.cwandt.com

**Date:** 2026-07-16
**Goal:** Let CW&T team members download and install the Crowsflight iOS test build over-the-air from a page hosted on `experiments.cwandt.com`, without TestFlight.

## Decisions (locked)

| Question | Decision |
|---|---|
| Distribution mechanism | Self-hosted **ad-hoc OTA** (`.ipa` + `itms-services` manifest) on the DreamHost VPS |
| Apple account | Paid **CW&T org** membership, team `L6DVQR8JB9` |
| Signing | **Interactive in Xcode** — the human handles org cert creation + device registration in Xcode's GUI; the pipeline scripts archive → export → host |
| Tester devices | **Start with known device(s)** already on hand; add UDIDs later as they come in |
| Build source | **Current `widget` branch as-is.** If the widget/watch target fails to archive, STOP and fix wiring first (do not exclude it) |

## Hard constraints (iOS reality)

- Ad-hoc installs only on devices whose **UDID is registered** in the ad-hoc provisioning profile (100 devices/yr cap). New tester = register UDID + re-export + re-upload.
- `itms-services` requires the manifest, `.ipa`, and both icons to be served over **HTTPS with a valid cert**. `experiments.cwandt.com` is live over HTTPS but 301-redirects apex → `www.`. Host at a clean `https://www.experiments.cwandt.com/crowsflight/` path so the manifest URL is not itself a redirect.
- Ad-hoc builds expire when the distribution cert / profile expires (~1 year).

## Current state (verified)

- Xcode 26.6; targets: `Crowsflight`, `Crowsflight Share`, `CrowsflightWidget.Extension` (+ watch, tests).
- Bundle IDs: `com.cwandt.crowsflight`, `.share`, `.CrowsflightWidget-` (note trailing hyphen — a real in-progress artifact to confirm during archive).
- Signing: **Automatic**, team `L6DVQR8JB9`. **No distribution cert present**; keychain has only personal-team dev certs (`66B4FE4L32`, `XZCX966PV5`). Xcode logged in as `cwwang@gmail.com` — its org membership/role for `L6DVQR8JB9` is unconfirmed.
- Version `1.9.0`. Repo `github.com/cheewee2000/Crowsflight-iOS`, branch `widget`.

## Pipeline architecture

Each stage is a discrete, independently runnable script committed to the repo under `scripts/ota/`.

```
[Xcode GUI: cert + UDID]  →  archive.sh  →  export.sh  →  package_ota.sh  →  deploy.sh
   (human, one-time)         (.xcarchive)   (.ipa)        (manifest+page)    (VPS rsync)
```

### Stage 0 — Signing prerequisites (human, interactive in Xcode)
1. Confirm `cwwang@gmail.com` (or an added org account) is a member of team `L6DVQR8JB9` with rights to create signing assets. If not, resolve access first.
2. In Xcode → Settings → Accounts, and the target's Signing & Capabilities, let Xcode create an **Apple Distribution** certificate for `L6DVQR8JB9`.
3. Register the known tester device UDID(s) (Xcode → Devices, or the Developer portal), and generate **ad-hoc** provisioning profiles covering all three shippable bundle IDs.
   - **Verification of this stage:** `security find-identity -v -p codesigning` shows an `Apple Distribution` identity for `L6DVQR8JB9`; ad-hoc profiles for the three bundle IDs exist in `~/Library/MobileDevice/Provisioning Profiles/`.

### Stage 1 — `archive.sh`
- `xcodebuild -project Crowsflight.xcodeproj -scheme Crowsflight -configuration Release -archivePath build/ota/Crowsflight.xcarchive archive`
- Uses automatic signing; the human-approved distribution cert/profiles are picked up.
- **If archive fails on the widget/watch target → STOP** (per decision) and surface the error for a wiring fix.

### Stage 2 — `export.sh`
- `xcodebuild -exportArchive -archivePath build/ota/Crowsflight.xcarchive -exportPath build/ota/export -exportOptionsPlist scripts/ota/ExportOptions.plist`
- `ExportOptions.plist`: `method = release-testing` (ad-hoc), `teamID = L6DVQR8JB9`, `signingStyle = automatic`, `thinning = <none>`, `compileBitcode = NO`.
- Output: `build/ota/export/Crowsflight.ipa` + Xcode's own `manifest.plist` (we regenerate ours in Stage 3 for correct URLs/icons).

### Stage 3 — `package_ota.sh`
- Read `MARKETING_VERSION` / build from the archive's `Info.plist` (single source of truth for the version shown on the page).
- Generate `manifest.plist` with: software `url` (IPA HTTPS URL), `display-image` (57×57 PNG HTTPS), `full-size-image` (512×512 PNG HTTPS), `bundle-identifier` `com.cwandt.crowsflight`, `bundle-version`, `title` "Crowsflight".
- Extract 57px + 512px PNG icons from the app's asset catalog / archive.
- Generate `index.html` landing page (see Components).
- Assemble a `dist/crowsflight/` folder: `Crowsflight.ipa`, `manifest.plist`, `icon-57.png`, `icon-512.png`, `index.html`, favicon assets.

### Stage 4 — `deploy.sh`
- rsync `dist/crowsflight/` → `cwandt@vps52023.dreamhostps.com:~/experiments.cwandt.com/crowsflight/` (confirm actual docroot on first run).
- Ensure Apache serves correct MIME types: `.ipa` → `application/octet-stream`, `.plist` → `text/xml` (add a `.htaccess` in the crowsflight dir if needed).
- Post-deploy verification: `curl -I` each of `index.html`, `manifest.plist`, `Crowsflight.ipa`, both icons over HTTPS → all `200`, correct `content-type`, no redirect on the manifest URL.

## Components

- **`scripts/ota/ExportOptions.plist`** — ad-hoc export config (committed).
- **`scripts/ota/*.sh`** — the four stage scripts above; idempotent, safe to re-run; a `build_and_deploy.sh` wrapper runs Stages 1→4.
- **Landing page `index.html`** — hosted on `experiments.cwandt.com/crowsflight/`. Contains:
  - App name, icon, visible **version number** (from build; bumped every release per CW&T convention).
  - The install button: `itms-services://?action=download-manifest&url=https://www.experiments.cwandt.com/crowsflight/manifest.plist`.
  - Short install instructions (open in Safari on iPhone; tap Install; if iOS prompts, trust the CW&T developer under Settings → General → VPN & Device Management — **verify actual prompt on a real device and adjust copy**).
  - A note that only registered devices can install, with a "send me your UDID" line for new testers.
  - **Favicon** per CW&T convention: solid color circle, 50% width, centered, transparent bg; color chosen for this project (proposed `#000000` or a Crowsflight brand color — confirm). Generate favicon.ico + 16/32 PNGs + 180 apple-touch-icon.
- **GitHub repo** — per CW&T convention, a repo for the `experiments.cwandt.com/crowsflight` landing site + OTA scripts. (Decision at plan time: standalone `experiments-cwandt-com` site repo vs. keeping `scripts/ota/` inside the app repo and only the page in a site repo. Recommendation: page + deploy scripts in a small site repo; keep build scripts referencing the app repo.)

## Data flow

Build machine (this Mac) produces `.ipa` + `manifest.plist` + icons → rsync to VPS → tester opens page in Safari on a **registered** iPhone → taps install button → iOS reads `manifest.plist` → downloads `.ipa` over HTTPS → installs.

## Error handling

- **Archive fails on widget/watch target** → stop, report exact error (per decision).
- **No distribution identity / profile** → stop at Stage 1 with a clear message pointing back to Stage 0.
- **Device not registered** → tester install fails silently on-device; page documents "registered devices only" + UDID request. We cannot detect this server-side.
- **Manifest URL redirects or bad MIME** → install fails; Stage 4 `curl` checks catch this before we announce the link.
- **Cert/profile expiry (~1yr)** → future re-sign + re-export; out of scope for this pass but noted.

## Testing / verification

1. Stage 0 verified via `security find-identity` + profile presence.
2. Stages 1–2 verified by a successfully produced, correctly-signed `.ipa` (`codesign -dv` shows Apple Distribution / team `L6DVQR8JB9`; embedded profile is ad-hoc with the known UDID).
3. Stage 4 verified via `curl -I` on all hosted assets.
4. **End-to-end:** install on the one known registered device from the live page. This is the real acceptance test — a green build is not "done" until it installs from `experiments.cwandt.com/crowsflight/`.

## Out of scope (this pass)

- TestFlight; enterprise distribution.
- Self-service UDID enrollment page (may add later).
- CI automation of the pipeline.
- Finishing widget/watch target wiring (only relevant if it blocks the archive).

## Open items to resolve during planning

- Confirm `cwwang@gmail.com`'s org role on `L6DVQR8JB9` (Stage 0 may reveal we need a different login).
- The known device UDID value (needed to register — the memory's "device id" may be a simulator id, not a real-device UDID).
- Favicon color for the landing page.
- Site repo shape (standalone vs. in-app scripts).

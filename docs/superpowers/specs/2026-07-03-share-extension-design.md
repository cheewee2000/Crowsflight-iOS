# "Share to Crowsflight" Extension — Design

**Date:** 2026-07-03
**Status:** Approved for planning

## Purpose

Let a user share a single place from the Google Maps or Apple Maps iOS app into
Crowsflight. The shared place is appended to the saved-places list and becomes
the current navigation target, so opening Crowsflight points at it immediately.

Out of scope (deliberately): Google Maps *list* links (bulk import), Google
Takeout file import, arbitrary URLs from other apps, any form of ongoing sync.
Google offers no saved-places API outside the EEA/UK Data Portability API, so
per-place share is the sanctioned worldwide path.

## Background

- Saved places live in `Documents/locationList.plist` — an array of 4-key
  dictionaries: `searchedText` (name), `address` (currently a vestigial
  placeholder string), `lat`, `lng`.
- All writes funnel through `cwtAppDelegate addNewDestination:newlat:newlng:`
  (`cwtAppDelegate.m:392`), which appends to the array, writes the plist, sets
  `currentDestinationN` (NSUserDefaults) to the new entry, syncs iCloud KVS,
  and transfers the plist to the Watch.
- A share extension runs in its own process: it cannot call the app's code,
  read the app's Documents directory, or (legitimately) open the app. Handoff
  is via an App Group.
- Main app bundle ID: `com.cwandt.crowsflight`.

## Architecture

```
Google/Apple Maps ──share──▶ Crowsflight Share extension (own process)
                                │ extract URL from shared URL/text
                                │ resolve short link, parse name + lat/lng
                                │ (CLGeocoder fallback on name)
                                ▼
                    App Group shared NSUserDefaults
                    suite: group.com.cwandt.crowsflight
                    key: pendingImports (array of dicts)
                                │
        Crowsflight launch / applicationDidBecomeActive
                                ▼
              drain queue → dedupe → addNewDestination:
              (plist + currentDestinationN + iCloud + Watch)
```

## Components

### 1. Xcode target: `Crowsflight Share`

- Share Extension target, **Swift** (precedent: the Watch extension is Swift;
  the main app stays ObjC).
- Bundle ID `com.cwandt.crowsflight.share`.
- Activation: `NSExtensionActivationRule` accepting **one web URL or plain
  text** (`NSExtensionActivationSupportsWebURLWithMaxCount = 1`,
  `NSExtensionActivationSupportsText = YES`). Google Maps often shares
  "Check out <name>! https://maps.app.goo.gl/…" as text, so the extension must
  extract the first URL from text payloads too.
- App Group capability `group.com.cwandt.crowsflight` on **both** the main app
  and the extension. This requires the group to be registered on the Apple
  developer portal and both provisioning profiles to include it — a signing
  step, not code. The project's 2013-era signing setup may need updating first.

### 2. `PlaceURLResolver` (Swift, in the extension target)

Self-contained and unit-testable: pure URL parsing separated from network
redirect-following.

Input: a URL (or text containing one). Output: `ResolvedPlace { name: String,
address: String?, lat: Double, lng: Double }` or a typed failure.

Resolution steps:

1. **Extract URL** from the shared item (URL attachment or first URL in text).
2. **Expand short links**: `maps.app.goo.gl/...` (and `goo.gl/maps/...`) —
   follow HTTP redirects (no HTML parsing) to the full `google.com/maps` URL.
3. **Parse Google Maps URLs**, coordinate sources in priority order:
   - `!3d<lat>!4d<lng>` in the data blob — the actual place pin (best),
   - `q=<lat>,<lng>` query param,
   - `@<lat>,<lng>,<zoom>` — viewport center (least accurate, last resort).
   Name: percent-decoded `/maps/place/<name>/` path segment, else the
   non-URL part of the shared text, else reverse-geocoded description.
4. **Parse Apple Maps URLs** (`maps.apple.com`): `ll=<lat>,<lng>`,
   `coordinate=<lat>,<lng>`; name from `q=` or `name=` or `address=`.
5. **Geocode fallback**: name present but no usable coordinates → `CLGeocoder`
   forward-geocode the name (extension processes may use CoreLocation
   geocoding; no location permission needed).
6. **Sanity checks**: reject (0,0) (known Google export/redirect bug), reject
   out-of-range lat/lng, require non-empty name (the Watch parser
   force-unwraps `searchedText` — `ExtensionDelegate.swift:92-123`).

### 3. Extension UI

Minimal auto-completing card (no compose sheet, no options):

- Spinner + "Reading location…" while resolving (network redirect + parse).
- On success: place name + "Added to Crowsflight ✓", auto-dismiss (~1 s),
  after writing to the inbox.
- On failure: "Couldn't read a location from this share." with a Cancel
  button; nothing is written.

### 4. App Group inbox

- Shared `NSUserDefaults(suiteName: "group.com.cwandt.crowsflight")`.
- Key `pendingImports`: array of dictionaries
  `{searchedText: String, address: String, lat: NSNumber, lng: NSNumber}` —
  deliberately the same shape as the app's saved-place schema. `address` gets
  the real address when the resolver has one, else `""` (the field is
  currently dead weight in the app; every reader tolerates arbitrary strings).
- Extension appends; the app drains and deletes the key. Typical queue depth
  is 1; NSUserDefaults is fine (no file coordination needed).

### 5. Main app ingestion (ObjC, `cwtAppDelegate`)

New method `drainPendingImports`, called from
`application:didFinishLaunchingWithOptions:` and
`applicationDidBecomeActive:`:

- Read and clear `pendingImports` from the shared suite (clear first, then
  process, so a crash mid-import can't double-add on next launch).
- For each entry, **dedupe**: if an existing place in
  `locationDictionaryArray` has the same coordinates rounded to 4 decimal
  places (~11 m), do not re-add — set `currentDestinationN` to that existing
  index instead (still honors "make it the target").
- Otherwise call the existing `addNewDestination:newlat:newlng:` — reusing the
  canonical path so plist, `currentDestinationN`, iCloud KVS, and Watch
  transfer all stay consistent. `lat`/`lng` are passed so they are stored as
  numbers (matching the seed plist and `editDestination`).
- Refresh visible UI the same way the existing URL-scheme handler
  (`cwtAppDelegate.m:160-206`) does after an external add.

## Error handling

| Failure | Behavior |
|---|---|
| No URL in shared item | Extension error card, nothing written |
| Short-link expansion fails (offline) | Error card: needs network; nothing written |
| URL parses but no coords and geocoder fails | Error card, nothing written |
| Coords (0,0) or out of range | Treated as "no coords" → geocode fallback → else error card |
| Empty/missing name | Fall back to shared-text remainder, then reverse-geocode; never write an entry without `searchedText` |
| App Group suite unavailable (signing misconfig) | Extension error card; log; nothing written |
| Duplicate place | Not an error: select existing entry as target |

## Testing

- **Unit tests** (extension target): `PlaceURLResolver` parsing against a
  corpus of real captured share URLs — Google place links (short + expanded,
  with `!3d!4d`, with only `@`), `q=lat,lng` links, Apple Maps `ll=` and
  `place?coordinate=` links, text-with-URL payloads, junk input, (0,0) case.
  Redirect-following is behind a protocol so tests run without network.
- **Manual end-to-end** (simulator/device per existing test-setup notes):
  share from Google Maps and Apple Maps → extension card shows correct name →
  open Crowsflight → place is last in list and is the current target → appears
  on the paired Watch. Repeat the same share → no duplicate, target selected.

## Risks / notes

- **Signing**: App Groups require the group registered under the team account
  and both targets' entitlements updated. On this vintage project, expect to
  spend time in Signing & Capabilities before any code runs on device.
- **Google URL format drift**: the `!3d!4d` / `@` conventions are
  long-standing but undocumented; the geocoder fallback and the parser test
  corpus are the mitigation.
- **Min iOS version**: the app's deployment target is iOS 14.0; the extension
  will match it. Share extensions are supported since iOS 8, so no constraint.

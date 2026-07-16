# Crowsflight Home-Screen Widget — Design

**Date:** 2026-07-16
**Status:** Approved design, ready for implementation planning

## Summary

A WidgetKit home-screen widget for Crowsflight that reproduces the app's face —
translucent yellow bearing cone, white underlay circle, blue distance arc, and the
centered distance readout — at three sizes (small, medium, large). Because a widget
process has no live compass, the cone points to a **static north-up bearing** (map
style) rather than a device-relative heading, and distance/bearing refresh on the
WidgetKit timeline rather than continuously.

Non-goals: live compass rotation, a quick-launch list of other destinations, Lock
Screen accessories. (All considered and explicitly deferred.)

## Constraints & honesty notes

- **No live heading.** The widget cannot rotate with the device. The cone is rotated
  to the destination's true north-up bearing. This is a map bearing, not "point your
  phone this way."
- **No continuous updates.** WidgetKit refreshes on a timeline within an OS budget
  (~dozens/day). We target ~15 min cadence, plus an app-driven reload when the app
  writes a fresh snapshot.
- **Cone width means positional uncertainty only.** The app's cone `spread` is
  `headingAccuracy + bearingAccuracy` (`cfLocationViewController2.m:506`). The widget
  has no heading term, so its spread reflects **bearing/positional uncertainty** from
  GPS accuracy at the current distance. Documented so the cone isn't misread as heading
  confidence.
- **Staleness is surfaced.** An "updated Xm ago" line is always shown. Past a
  staleness threshold the readout is visually dimmed (see Stale behavior).

## Architecture

### Targets & app group

- New app extension target **`CrowsflightWidget`** (WidgetKit + SwiftUI).
- Joins the existing app group **`group.com.cwandt.crowsflight`** (already shared by
  the app and the share extension — see `Crowsflight.entitlements`,
  `CrowsflightShare.entitlements`). No new container needed.
- Swift, matching the existing modern Swift surface (`SharedPlaces` SPM package,
  `ShareViewController.swift`). Shared geo math can live in a small Swift file compiled
  into both the app and the widget (candidate: extend the `SharedPlaces` package with a
  `Geo`/`WidgetSnapshot` module so the app and widget share one source of truth).

### Data contract (app → widget)

The main app writes a single snapshot to the app group whenever it recomputes
location/destination and on `applicationDidEnterBackground` / `willResignActive`.
Stored under the shared `UserDefaults(suiteName: "group.com.cwandt.crowsflight")` as a
JSON-encoded value (key `widgetSnapshot`), or an equivalent JSON file in the group
container.

```
WidgetSnapshot {
  destinationName: String
  destLat: Double
  destLng: Double
  destinationIndex: Int      // currentDestinationN
  destinationCount: Int      // total saved places, for the "n/total" indicator
  userLat: Double            // last known user fix
  userLng: Double
  accuracyMeters: Double     // horizontal accuracy of that fix
  units: String              // "m" or "km" (mirrors dele.units)
  timestamp: Date            // when the user fix was taken
}
```

Writing this is additive to the app: a small `WidgetSnapshotWriter` invoked from the
same place the app already computes distance/bearing (`cfLocationViewController2`) and
from the app delegate on background transitions. After writing, call
`WidgetCenter.shared.reloadAllTimelines()` so the widget picks up destination changes
promptly.

### Widget timeline provider (hybrid location)

On each timeline request:

1. Read `WidgetSnapshot` from the app group. If absent, render the placeholder /
   "open Crowsflight to set a destination" state.
2. **Hybrid location:** attempt a fresh fix via `CLLocationManager` widget location
   (iOS 17+, `requestLocation` in the provider). If authorized and a fix returns within
   budget, use it as the user position and recompute; otherwise fall back to the
   snapshot's `userLat/userLng/accuracy/timestamp`.
3. Compute the render model (all math ported 1:1 from the app):
   - **distance** — great-circle using the app's Earth radius constants
     (`EARTH_RAD_M 3956.0` mi / `EARTH_RAD_KM 6367.0` km,
     `cfLocationViewController2.m:12-13`).
   - **bearing** — `atan2(sin(dLon)·cos(lat2), cos(lat1)·sin(lat2) −
     sin(lat1)·cos(lat2)·cos(dLon))`, normalized to 0–360
     (`cfLocationViewController2.m:436-440`).
   - **arc progress** — `((ln(1+meters)/ln(100))·0.275 − 0.2)·359`, clamped `[5,359]`
     (`cfLocationViewController2.m:330`, `cwtDrawArc.m:67-70`). Swept angle =
     `360 − progress` from the top, clockwise (ring fills as you approach).
   - **cone spread** — angular positional uncertainty from `accuracyMeters` at
     `distance` (the `bearingAccuracy` idea, `cfLocationViewController2.m:442-446`),
     clamped like the app (`spread ≤ 1 → 88`, `> 180 → 180`, `cwtArrow.m:48-49`). No
     heading term.
   - **staleness** — `now − timestamp`.
4. Emit a single timeline entry with refresh policy `.after(now + ~15 min)`.

### Widget view (SwiftUI)

One `View` parameterized by `WidgetFamily`, supporting `.systemSmall`,
`.systemMedium`, `.systemLarge`. Layers, bottom to top:

1. **Cone** — filled wedge, `#ffff00` at 0.7 opacity, apex at center, rotated to the
   north-up bearing, half-angle = spread.
2. **White underlay circle** — `#f9f9f9` (`white:.975`, `cwtDrawArc.m:115`), radius
   `underlayRadius`, masks the cone behind the readout.
3. **Blue track** — 1px full circle, `#00BAFF` (`rgb(0,.73,1)`), radius `r`.
4. **Blue progress arc** — thick stroke width `t`, `#00BAFF`, from the top "0" tick,
   swept `360 − progress` clockwise. Plus the small "0" tick at top.
5. **Readout** — centered stack: accuracy (`± N'`), distance number
   (HelveticaNeue-Light), unit label; destination name at top; `n/total` page
   indicator bottom-right; "updated Xm ago" bottom-left.

Proportions follow the app, scaled per family (reference ratios to underlay radius
`U`: `r = 1.583·U`, `t = 0.333·U`, `dialOuter = 1.75·U`). Large ≈ 1:1 app scale
(`U=60, r=95, t=20`).

Colors: field `#f9f9f8`, cone `#ffff00`@0.7, arc/track `#00BAFF`, number
`white:.1 (#1a1a1a)`, name `white:.2 (#333)`, accuracy `#555`, page/freshness mono
gray.

### Stale behavior

- Always show "updated Xm ago".
- Below the staleness threshold: full-opacity readout and arc.
- **At/above the threshold (default 30 min): dim/de-emphasize** the distance number
  and blue arc (reduced opacity) to signal the value isn't fresh, while keeping the
  destination name and cone legible. Threshold is a single tunable constant.

### Tap behavior

Each widget uses `widgetURL(URL("crowsflight://destination/<n>"))`. The app delegate
handles the URL (`application:openURL:`) by selecting `currentDestinationN = n` and
flipping to that page (reuse the existing `flipToPage:` path). Registering the
`crowsflight` URL scheme is additive to `Crowsflight-Info.plist`.

## Components & responsibilities

- **`WidgetSnapshot` (shared model)** — Codable struct + the geo math (distance,
  bearing, progress, spread). One implementation shared by app and widget. What it
  does: pure computation from coordinates + accuracy → render values. Depends on:
  nothing (Foundation only). Testable in isolation with known coordinate pairs.
- **`WidgetSnapshotWriter` (app side)** — writes the snapshot to the group and calls
  `WidgetCenter.reloadAllTimelines()`. Depends on: app's current location/destination
  state. Invoked from `cfLocationViewController2` update path and app-delegate
  background hooks.
- **`Provider` (widget side)** — `TimelineProvider`: reads snapshot, does hybrid
  location, builds entries. Depends on: `WidgetSnapshot`, `CLLocationManager`.
- **`CrowsflightWidgetView` (widget side)** — SwiftUI rendering per family. Depends on:
  the computed render model only (no I/O), so it previews with fixed data.
- **App-delegate URL handler** — maps `crowsflight://destination/<n>` to page flip.

## Data flow

```
App (location/destination update)
  └─ WidgetSnapshotWriter → app group (JSON) → WidgetCenter.reload
Widget refresh (timeline)
  ├─ read snapshot from app group
  ├─ hybrid: CLLocationManager fresh fix OR snapshot fix
  ├─ WidgetSnapshot math → distance / bearing / progress / spread / staleness
  └─ CrowsflightWidgetView renders (small / medium / large)
Tap → crowsflight://destination/n → app selects destination n
```

## Error / edge handling

- **No snapshot yet** → placeholder state prompting to open the app and set a
  destination.
- **No location permission for the widget** → fall back to snapshot fix; if that's also
  absent, show destination name only.
- **Stale fix** → dim readout as above.
- **Distance ~0 / at destination** → progress clamps to 5 (near-full ring); guard
  divide-by-zero in the spread/uncertainty calc.
- **Antimeridian / polar bearings** → the `atan2` formula already handles wraparound;
  covered by tests.
- **Units** → mirror `dele.units`; format miles/km and the `± N'` / `± N m` accuracy
  exactly like `cfLocationViewController2.m:306-311`.

## Testing

- **Geo math unit tests** (in `SharedPlaces` or a sibling test target): distance and
  bearing against known city pairs; progress/clamp boundaries (distance 0, small, large);
  spread clamping; unit formatting. These are the correctness-critical pieces and are
  pure functions.
- **Snapshot round-trip test**: encode → app group → decode equals original.
- **View previews**: SwiftUI previews for all three families across states (fresh,
  stale/dimmed, no-destination, at-destination) for visual regression by eye.
- **Manual on-device**: add each size to the home screen; verify refresh after moving,
  the app-write reload on destination change, and tap-through deep link. (Follows the
  existing on-device test practice noted for the share extension.)

## Deferred / future

- Lock Screen accessories (circular/inline/rectangular).
- Quick-launch list of other saved destinations (large size has room).
- Live-updating anything (not possible in-widget by design).

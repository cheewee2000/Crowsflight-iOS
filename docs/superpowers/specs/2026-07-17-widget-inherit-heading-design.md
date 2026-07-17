# Widget Inherits App Heading — Design

**Date:** 2026-07-17
**Goal:** When the user exits the main app, the home-screen widget's dial should orient to the app's actual device heading (compass) captured at exit — matching the arrow the user was just looking at — instead of course-over-ground.

## Problem

The app and widget disagree on the dial's "up" reference:

- **App** orients by **device heading**: `cfLocationViewController2.m` rotates the arc by `locBearing − dele.heading`, where `dele.heading = newHeading.trueHeading` from `didUpdateHeading:`.
- **Widget** orients by **course over ground**: `makeRenderModel` sets `headingDegrees = course >= 0 ? course : 0`.

The snapshot written on background (`applicationDidEnterBackground → refreshWidgetSnapshot → WidgetBridge.writeSnapshot`) carries `course` but not `heading`. So on exit the widget can snap to a different rotation than the app's arrow.

## Decision

Carry the app's `heading` through the snapshot and orient the widget by it, with fallback **heading → course → north-up**.

- Heading validity uses the same convention as `course`: a value `>= 0` is valid; `< 0` means invalid.
- The app writes `self.heading` when `self.headingAccuracy >= 0`, otherwise `-1`. The app already calls `stopUpdatingHeading` in `applicationWillResignActive:`, so at `applicationDidEnterBackground:` time `self.heading` holds the last good compass value — the "inherited" heading.
- No new live sensing in the widget; widgets can't run CoreLocation heading. The value is frozen at exit, which is the intent.

## Changes

1. **`SharedPlaces/Sources/SharedPlaces/WidgetSnapshot.swift`** — add stored property `heading: Double` and constructor param (after `course`). Doc-comment mirrors `course`'s "< 0 when invalid".
2. **`CrowsflightWidget./WidgetSnapshot.swift`** — same field added to the widget's copy (kept field-for-field identical; project shares by target membership, not a linked module).
3. **`Crowsflight/WidgetBridge.swift`** — private mirror struct gains `heading`; `writeSnapshot(...)` ObjC selector gains a `heading:` parameter appended after `course:`; new selector `writeSnapshotWithName:...:course:heading:`.
4. **`Crowsflight/cwtAppDelegate.m`** (`refreshWidgetSnapshot`) and **`Crowsflight/cfLocationViewController2.m:378`** — both `writeSnapshot` call sites pass `heading:` = `self.headingAccuracy >= 0 ? self.heading : -1` (appDelegate) / the equivalent `dele` accessor at the location-VC site.
5. **`CrowsflightWidget./CrowsflightGeo.swift`** (`makeRenderModel`) — add `heading: Double` param; compute dial-up as: `heading >= 0 ? heading : (course >= 0 ? course : 0)`. Update the doc-comment on `RenderModel.headingDegrees`.
6. **`CrowsflightWidget./Provider.swift`** — pass `heading: snap.heading` into `makeRenderModel`; update `sampleModel`/preview literals as needed (they set `headingDegrees` directly, so only new call args matter).

## Data flow

`didUpdateHeading:` → `dele.heading` (live while app active) → on background, `refreshWidgetSnapshot` writes `heading` into the app-group snapshot → widget `Provider.makeEntry` reads it → `makeRenderModel` uses it as dial "up" → `DialView` rotates by `-headingDegrees`, cone points to `bearingDegrees − headingDegrees`.

## Testing

- **`WidgetSnapshotStoreTests`** — extend the round-trip test to include `heading` (write a snapshot with a heading, read it back, assert equality). Confirms Codable shape stays in sync between app writer and widget reader.
- **`CrowsflightGeoTests`** — add `makeRenderModel` cases:
  - valid heading + valid course → `headingDegrees == heading` (heading wins).
  - invalid heading (`-1`) + valid course → `headingDegrees == course` (fallback preserved).
  - both invalid → `headingDegrees == 0` (north-up).

## Out of scope

- Any live/periodic heading update in the widget (impossible for widgets).
- Changing the app's own arrow logic.
- Magnetic-vs-true heading choice (app already uses `trueHeading`; unchanged).

## Compatibility note

Adding a field to the Codable snapshot: an old widget reading a new snapshot, or vice versa, would fail to decode the changed shape and fall back to the "no snapshot" placeholder until the next write. Since app + widget ship together from one build and the app rewrites the snapshot on next background, this self-heals immediately. Acceptable.

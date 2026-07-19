# Crowsflight Apple Watch App — Design

Date: 2026-07-19
Status: approved (Approach A)

## Goal

Rebuild the Apple Watch app that was removed on 2026-07-16 (commit ae66da9,
legacy `watchapp2` product types blocked Xcode 26 builds). V1 scope, per user:
**live compass face + destination switching on the watch**. Complication is
explicitly deferred to v2. Notification scaffolding from the old app is dropped.

## Target & platform

- New watchOS **app** target `CrowsflightWatch` — modern single-target watch app
  (`com.apple.product-type.application`, watchOS SDK), SwiftUI lifecycle, no
  WatchKit extension target.
- Deployment: **watchOS 10.0** (user's watch is Series 6 or newer).
- Embedded in the iOS app (`com.cwandt.crowsflight.watchkitapp` bundle id
  namespace is free again; use `com.cwandt.crowsflight.watch`).
- Target created manually in Xcode by the user (proven path from the widget
  build — avoids risky pbxproj surgery); folder uses an Xcode file-system
  synchronized group so any file dropped in it compiles automatically.

## Code sharing

Same pattern as the widget: canonical, unit-tested sources live in the
`SharedPlaces` SPM package; the watch target compiles its own **copies**
(with the standard `// COPY of …` header) because the project shares by
target membership, not module linking.

Shared into the watch folder: `CrowsflightGeo.swift` (distance/bearing/arc/
spread/formatting + `RenderModel` + `makeRenderModel`), `WatchSyncPayload.swift`
(new). `DialView` is ported (not copied verbatim) from the widget since sizing
and live-heading behavior differ.

## Components

### Watch side (folder `CrowsflightWatch/`)

- **`CrowsflightWatchApp.swift`** — `@main` SwiftUI app.
- **`WatchDestinationStore`** — `NSObject, WCSessionDelegate, ObservableObject`.
  Activates `WCSession`, receives `didReceiveApplicationContext`, decodes
  `WatchSyncPayload`, persists the raw JSON to `UserDefaults` (standalone/offline
  operation), publishes `[WatchSyncPayload.Destination]` + `units`. On launch,
  loads cache first, then `WCSession.receivedApplicationContext` if newer.
- **`WatchLocationProvider`** — `NSObject, CLLocationManagerDelegate,
  ObservableObject`. Requests When-In-Use on the watch, publishes latest fix
  (lat/lng/accuracy/course) and live magnetometer heading
  (`startUpdatingHeading`; watches Series 5+ have a compass). Stops updates
  when the scene backgrounds.
- **`WatchDialView`** — port of the widget `DialView`: yellow bearing cone
  rotated to `bearing - heading`, white underlay circle, blue distance arc
  (mirrored sweep, matching commit b5b2a28), red N marker at `-heading`,
  centered distance readout + destination name. Driven by `RenderModel`.
- **`ContentView`** — `TabView` with `.verticalPage` style (crown-scrollable),
  one page per destination; selection is watch-local (not synced back to the
  phone). Placeholder page "Open Crowsflight on your iPhone" when the
  destination list is empty. Heading fallback chain identical to widget:
  live heading → course → north-up (0), all via `makeRenderModel`.

### Shared (`SharedPlaces`, TDD)

- **`WatchSyncPayload`** — `Codable`: `[Destination]` (`name`, `lat`, `lng`),
  `units` (`"m"`/`"km"` convention as used by the app), `version: Int` (=1),
  `timestamp: Date`. JSON encode/decode helpers with default coder settings.
  Unit tests: round-trip, unknown-field tolerance, empty list.

### Phone side

- **`WatchSyncBridge.swift`** — self-contained `@objc` bridge (same pattern as
  `WidgetBridge`, duplicating the payload struct field-for-field with a
  keep-in-sync comment). Static method takes parallel arrays (names, lats,
  lngs) + units, encodes JSON, calls
  `WCSession.default.updateApplicationContext(_:)` when the session is
  activated/paired/watch-app-installed. Errors are logged, never fatal.
- **ObjC call sites**: on `activationDidCompleteWithState` (replacing the
  legacy `transferLocations` file transfer, which is deleted) and wherever
  `locationDictionaryArray` is persisted (add/edit/delete of destinations),
  plus units changes.

## Data flow

Phone saves destinations → `WatchSyncBridge` encodes `WatchSyncPayload` →
`updateApplicationContext` (latest-wins, delivered even if the watch app is
closed) → `WatchDestinationStore` decodes + caches → `ContentView` pages.
Watch `WatchLocationProvider` streams fix + heading → `makeRenderModel`
per update → `WatchDialView`.

## Error handling

- No destinations: placeholder page (see above).
- Watch location not authorized: page shows dial with prompt text underneath;
  request authorization on first appear.
- No heading (rare on Series 6+): course fallback → north-up, silent.
- `updateApplicationContext` throws (e.g. not paired): log and continue.
- Stale/no fix on watch: dial renders with last-known fix; no staleness dimming
  in v1 (live app in the foreground, unlike the widget).

## Testing

- `SharedPlaces`: `swift test` — payload codec tests (TDD, red first).
- Build: `xcodebuild` full "Crowsflight" scheme (simulator, signing off) must
  succeed with the watch app embedded; watch-only scheme build too.
- On-device: user verifies sync (destinations appear), live compass rotation,
  crown/swipe switching, standalone behavior (phone out of range).

## Ship

- Version: 1.9.2 → **1.10.0** across app + extensions + watch.
- Commit, push, OTA deploy via `scripts/ota/`.
- **Risk**: ad-hoc OTA with an embedded watch app may need watch provisioning
  cooperation. If OTA install fails: plan B is exporting the ad-hoc IPA without
  the watch app, or a one-time Xcode install for the watch build.

## Out of scope (v2 candidates)

- Watch-face complication (WidgetKit accessory family, reusing widget code).
- Notifications (old app's scaffolding dropped).
- Syncing the selected destination between phone and watch.

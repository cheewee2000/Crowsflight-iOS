//
//  Provider.swift
//  CrowsflightWidget
//
//  Timeline provider: reads the app-group snapshot and builds a RenderModel.
//  The user location is whatever the app last saw (persisted in the snapshot) —
//  the widget does not fetch its own location, so it always mirrors the app.
//

import WidgetKit
import SwiftUI

struct CrowsflightEntry: TimelineEntry {
    let date: Date
    let model: RenderModel?
    let destinationIndex: Int?
}

struct Provider: TimelineProvider {
    static let staleThreshold: TimeInterval = 30 * 60

    func placeholder(in context: Context) -> CrowsflightEntry {
        CrowsflightEntry(date: Date(), model: Self.sampleModel, destinationIndex: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (CrowsflightEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CrowsflightEntry>) -> Void) {
        // Fetch a fresh one-shot fix so the widget updates between app sessions
        // (NSWidgetWantsLocation). Falls back to the app snapshot on failure /
        // timeout / no authorization; the fetcher always completes exactly once.
        // The system may also skip delivery when the widget hasn't been visible
        // recently ("in use" window) — same fallback covers that.
        let fetcher = WidgetLocationFetcher()
        fetcher.fetch(timeout: 8) { fix in
            _ = fetcher // keep the fetcher (and its CLLocationManager) alive
            let entry = makeEntry(fresh: fix)
            let next = Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func makeEntry(fresh: FreshFix? = nil) -> CrowsflightEntry {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshotStore.suiteName),
              let snap = WidgetSnapshotStore.read(from: defaults) else {
            return CrowsflightEntry(date: Date(), model: nil, destinationIndex: nil)
        }
        let fix = resolveFix(snapshot: snap, fresh: fresh)
        let model = makeRenderModel(
            destinationName: snap.destinationName,
            destinationIndex: snap.destinationIndex,
            destinationCount: snap.destinationCount,
            destLat: snap.destLat, destLng: snap.destLng,
            userLat: fix.userLat, userLng: fix.userLng, accuracyMeters: fix.accuracyMeters,
            units: snap.units, course: fix.course, heading: fix.heading, fixTimestamp: fix.timestamp, now: Date(),
            staleThreshold: Self.staleThreshold)
        return CrowsflightEntry(date: Date(), model: model, destinationIndex: snap.destinationIndex)
    }

    static let sampleModel = RenderModel(
        destinationName: "Home", distanceValue: "2.30", distanceUnit: "MILES",
        accuracyText: "± 48'", bearingDegrees: 42, headingDegrees: 0, progress: 104, sweptDegrees: 256,
        spreadDegrees: 30, pageText: "1/5", isStale: false)
}

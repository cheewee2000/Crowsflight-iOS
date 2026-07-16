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
        // Re-render periodically so "updated Xm ago" and stale-dimming stay current
        // even though the distance only changes when the app writes a new snapshot.
        let entry = makeEntry()
        let next = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> CrowsflightEntry {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshotStore.suiteName),
              let snap = WidgetSnapshotStore.read(from: defaults) else {
            return CrowsflightEntry(date: Date(), model: nil, destinationIndex: nil)
        }
        let model = makeRenderModel(
            destinationName: snap.destinationName,
            destinationIndex: snap.destinationIndex,
            destinationCount: snap.destinationCount,
            destLat: snap.destLat, destLng: snap.destLng,
            userLat: snap.userLat, userLng: snap.userLng, accuracyMeters: snap.accuracyMeters,
            units: snap.units, course: snap.course, fixTimestamp: snap.timestamp, now: Date(),
            staleThreshold: Self.staleThreshold)
        return CrowsflightEntry(date: Date(), model: model, destinationIndex: snap.destinationIndex)
    }

    static let sampleModel = RenderModel(
        destinationName: "Home", distanceValue: "2.30", distanceUnit: "MILES",
        accuracyText: "± 48'", bearingDegrees: 42, headingDegrees: 0, progress: 104, sweptDegrees: 256,
        spreadDegrees: 30, pageText: "1/5", isStale: false)
}

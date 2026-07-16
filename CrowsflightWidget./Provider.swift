//
//  Provider.swift
//  CrowsflightWidget
//
//  Timeline provider: reads the app-group snapshot, optionally refreshes the
//  widget's own location (iOS 17+), and builds a RenderModel for the views.
//

import WidgetKit
import SwiftUI
import CoreLocation

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
        completion(makeEntry(freshLocation: nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CrowsflightEntry>) -> Void) {
        LocationFetcher.fetch { fresh in
            let entry = makeEntry(freshLocation: fresh)
            let next = Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func makeEntry(freshLocation: CLLocation?) -> CrowsflightEntry {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshotStore.suiteName),
              let snap = WidgetSnapshotStore.read(from: defaults) else {
            return CrowsflightEntry(date: Date(), model: nil, destinationIndex: nil)
        }
        let userLat = freshLocation?.coordinate.latitude ?? snap.userLat
        let userLng = freshLocation?.coordinate.longitude ?? snap.userLng
        let accuracy = freshLocation?.horizontalAccuracy ?? snap.accuracyMeters
        let fixTime = freshLocation?.timestamp ?? snap.timestamp
        let model = makeRenderModel(
            destinationName: snap.destinationName,
            destinationIndex: snap.destinationIndex,
            destinationCount: snap.destinationCount,
            destLat: snap.destLat, destLng: snap.destLng,
            userLat: userLat, userLng: userLng, accuracyMeters: accuracy,
            units: snap.units, fixTimestamp: fixTime, now: Date(),
            staleThreshold: Self.staleThreshold)
        return CrowsflightEntry(date: Date(), model: model, destinationIndex: snap.destinationIndex)
    }

    static let sampleModel = RenderModel(
        destinationName: "Home", distanceValue: "2.30", distanceUnit: "MILES",
        accuracyText: "± 48'", bearingDegrees: 42, progress: 104, sweptDegrees: 256,
        spreadDegrees: 30, pageText: "1/5", isStale: false)
}

/// Best-effort single location fix for the widget. iOS 17+ only; otherwise returns nil
/// immediately and the provider falls back to the snapshot fix.
enum LocationFetcher {
    static func fetch(_ completion: @escaping (CLLocation?) -> Void) {
        guard #available(iOS 17.0, *) else { return completion(nil) }
        Delegate.shared.request(completion)
    }

    @available(iOS 17.0, *)
    final class Delegate: NSObject, CLLocationManagerDelegate {
        static let shared = Delegate()
        private let manager = CLLocationManager()
        private var handler: ((CLLocation?) -> Void)?

        func request(_ completion: @escaping (CLLocation?) -> Void) {
            handler = completion
            manager.delegate = self
            let status = manager.authorizationStatus
            guard status == .authorizedWhenInUse || status == .authorizedAlways else {
                return finish(nil)
            }
            manager.requestLocation()
        }
        func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
            finish(locs.last)
        }
        func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
            finish(nil)
        }
        private func finish(_ loc: CLLocation?) {
            let h = handler; handler = nil; h?(loc)
        }
    }
}

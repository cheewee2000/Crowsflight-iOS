// Crowsflight/WatchSyncBridge.swift
//
// Objective-C-facing bridge that pushes the destination list to the watch via
// WCSession.updateApplicationContext (latest-wins, delivered even when the
// watch app is closed).
//
// Self-contained by design: mirrors SharedPlaces/WatchSyncPayload.swift
// field-for-field (same default JSONEncoder settings). Keep in sync with the
// canonical (unit-tested) WatchSyncPayload in the SharedPlaces package.

import Foundation
import WatchConnectivity

private struct Destination: Codable {
    var name: String
    var lat: Double
    var lng: Double
}

private struct Payload: Codable {
    var version: Int
    var destinations: [Destination]
    var units: String
    var timestamp: Date
}

@objc final class WatchSyncBridge: NSObject {

    @objc(pushDestinationsWithNames:lats:lngs:units:)
    static func pushDestinations(names: [String], lats: [NSNumber], lngs: [NSNumber], units: String) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired, session.isWatchAppInstalled else { return }
        guard names.count == lats.count, names.count == lngs.count else { return }
        let dests = (0..<names.count).map {
            Destination(name: names[$0], lat: lats[$0].doubleValue, lng: lngs[$0].doubleValue)
        }
        let payload = Payload(version: 1, destinations: dests, units: units, timestamp: Date())
        guard let data = try? JSONEncoder().encode(payload) else { return }
        do {
            try session.updateApplicationContext(["payload": data])
        } catch {
            NSLog("WatchSyncBridge: updateApplicationContext failed: %@", error.localizedDescription)
        }
    }
}

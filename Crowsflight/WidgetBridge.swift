//
//  WidgetBridge.swift
//  Crowsflight
//
//  Objective-C-facing bridge that publishes the current destination + last user
//  fix to the shared app group and reloads the widget timeline.
//
//  Self-contained by design: this project shares Swift by target membership, not a
//  linked module, and the app target only needs to WRITE the snapshot. The struct
//  below mirrors SharedPlaces/WidgetSnapshot.swift field-for-field; the widget reads
//  it back with the same default JSONEncoder/JSONDecoder settings. Keep the shape in
//  sync with the canonical (unit-tested) WidgetSnapshot in the SharedPlaces package.
//

import Foundation
import WidgetKit

private struct WidgetSnapshot: Codable {
    var destinationName: String
    var destLat: Double
    var destLng: Double
    var destinationIndex: Int
    var destinationCount: Int
    var userLat: Double
    var userLng: Double
    var accuracyMeters: Double
    var units: String
    var timestamp: Date
}

@objc final class WidgetBridge: NSObject {

    private static let suiteName = "group.com.cwandt.crowsflight"
    private static let key = "widgetSnapshot"

    @objc(writeSnapshotWithName:destLat:destLng:index:count:userLat:userLng:accuracy:units:)
    static func writeSnapshot(name: String, destLat: Double, destLng: Double,
                              index: Int, count: Int,
                              userLat: Double, userLng: Double, accuracy: Double,
                              units: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        let snap = WidgetSnapshot(
            destinationName: name, destLat: destLat, destLng: destLng,
            destinationIndex: index, destinationCount: count,
            userLat: userLat, userLng: userLng, accuracyMeters: accuracy,
            units: units, timestamp: Date())
        guard let data = try? JSONEncoder().encode(snap) else { return }
        defaults.set(data, forKey: key)
        if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
    }

    @objc static func reloadAll() {
        if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
    }
}

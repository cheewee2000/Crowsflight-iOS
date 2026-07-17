// COPY of SharedPlaces/Sources/SharedPlaces/CrowsflightGeo.swift — canonical + unit-tested in the SharedPlaces SPM package.
// This project shares code by target membership (Xcode file-system synchronized group),
// not a linked module, so the widget compiles its own copy. Keep the two in sync.

import Foundation
import CoreLocation

public enum CrowsflightGeo {

    public static func distanceMeters(userLat: Double, userLng: Double,
                                      destLat: Double, destLng: Double) -> Double {
        CLLocation(latitude: userLat, longitude: userLng)
            .distance(from: CLLocation(latitude: destLat, longitude: destLng))
    }

    public static func bearingDegrees(userLat: Double, userLng: Double,
                                      destLat: Double, destLng: Double) -> Double {
        let lat1 = userLat * .pi / 180
        let lat2 = destLat * .pi / 180
        let dLon = (destLng - userLng) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let deg = atan2(y, x) * 180 / .pi
        return (deg + 360).truncatingRemainder(dividingBy: 360)
    }

    public static func arcProgress(distanceMeters: Double) -> Double {
        var p = ((log(1 + distanceMeters) / log(100)) * 0.275 - 0.2) * 359
        if p >= 359 { p = 359 }
        if p <= 5 { p = 5 }
        return p
    }

    public static func sweptDegrees(progress: Double) -> Double { 360 - progress }

    public static func spreadDegrees(distanceMeters: Double, accuracyMeters: Double) -> Double {
        let raw = atan2(accuracyMeters, distanceMeters) * 180 / .pi
        return min(max(raw, 6), 90)
    }

    public static func distanceText(distanceMeters d: Double, units: String) -> (value: String, unit: String) {
        if units == "m" {
            if d < 402.336 { return (String(format: "%i", Int(d * 3.28084)), "FEET") }
            return (String(format: "%.2f", d * 0.000621371), "MILES")
        } else {
            if d < 1000 { return (String(format: "%i", Int(d)), "METERS") }
            return (String(format: "%.2f", d / 1000), "KM")
        }
    }

    public static func accuracyText(accuracyMeters a: Double, units: String) -> String {
        if units == "m" { return String(format: "± %i'", Int(a * 3.2808399)) }
        return String(format: "± %im", Int(a))
    }
}

public struct RenderModel: Equatable {
    public var destinationName: String
    public var distanceValue: String
    public var distanceUnit: String
    public var accuracyText: String
    public var bearingDegrees: Double
    /// Effective "up" heading for the dial: the app's device compass heading when
    /// valid, else course over ground, else 0 (north-up). The cone points to
    /// `bearingDegrees - headingDegrees`.
    public var headingDegrees: Double
    public var progress: Double
    public var sweptDegrees: Double
    public var spreadDegrees: Double
    public var pageText: String
    public var isStale: Bool
}

public func makeRenderModel(destinationName: String, destinationIndex: Int, destinationCount: Int,
                            destLat: Double, destLng: Double,
                            userLat: Double, userLng: Double, accuracyMeters: Double,
                            units: String, course: Double, heading: Double = -1,
                            fixTimestamp: Date, now: Date,
                            staleThreshold: TimeInterval) -> RenderModel {
    let dist = CrowsflightGeo.distanceMeters(userLat: userLat, userLng: userLng, destLat: destLat, destLng: destLng)
    let bearing = CrowsflightGeo.bearingDegrees(userLat: userLat, userLng: userLng, destLat: destLat, destLng: destLng)
    let progress = CrowsflightGeo.arcProgress(distanceMeters: dist)
    let text = CrowsflightGeo.distanceText(distanceMeters: dist, units: units)
    // Dial "up": inherit the app's device compass heading (what the arrow showed at
    // exit) when valid; else fall back to course over ground (direction of travel);
    // else north-up. Values < 0 are invalid.
    let dialUp = heading >= 0 ? heading : (course >= 0 ? course : 0)
    return RenderModel(
        destinationName: destinationName,
        distanceValue: text.value,
        distanceUnit: text.unit,
        accuracyText: CrowsflightGeo.accuracyText(accuracyMeters: accuracyMeters, units: units),
        bearingDegrees: bearing,
        headingDegrees: dialUp,
        progress: progress,
        sweptDegrees: CrowsflightGeo.sweptDegrees(progress: progress),
        spreadDegrees: CrowsflightGeo.spreadDegrees(distanceMeters: dist, accuracyMeters: accuracyMeters),
        pageText: "\(destinationIndex + 1)/\(destinationCount)",
        isStale: now.timeIntervalSince(fixTimestamp) > staleThreshold
    )
}

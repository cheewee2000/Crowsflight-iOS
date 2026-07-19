// CrowsflightWatch Watch App/WatchLocationProvider.swift
//
// Live GPS fix + magnetometer heading on the watch. Values mirror the
// makeRenderModel parameters; -1 means invalid for course/heading.

import Foundation
import Combine
import CoreLocation

final class WatchLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published private(set) var userLat: Double = 0
    @Published private(set) var userLng: Double = 0
    @Published private(set) var accuracyMeters: Double = 0
    @Published private(set) var course: Double = -1
    @Published private(set) var heading: Double = -1
    @Published private(set) var hasFix = false
    /// nil = not yet determined, false = denied/restricted, true = usable.
    @Published private(set) var authorized: Bool? = nil

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: authorized = true
        case .denied, .restricted: authorized = false
        case .notDetermined: authorized = nil
        @unknown default: authorized = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        userLat = loc.coordinate.latitude
        userLng = loc.coordinate.longitude
        accuracyMeters = max(loc.horizontalAccuracy, 0)
        course = loc.course
        hasFix = true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.headingAccuracy >= 0 ? newHeading.trueHeading : -1
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Transient CoreLocation errors (e.g. kCLErrorLocationUnknown) — keep last fix.
    }
}

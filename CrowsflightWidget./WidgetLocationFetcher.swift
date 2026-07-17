//
//  WidgetLocationFetcher.swift
//  CrowsflightWidget
//
//  One-shot location fetch for the timeline provider. Completion always fires
//  exactly once — with a FreshFix on success, or nil on failure/timeout/no
//  authorization — so getTimeline can always hand WidgetKit a timeline.
//

import Foundation
import CoreLocation

final class WidgetLocationFetcher: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var completion: ((FreshFix?) -> Void)?

    func fetch(timeout: TimeInterval, completion: @escaping (FreshFix?) -> Void) {
        guard manager.isAuthorizedForWidgetUpdates else {
            completion(nil)
            return
        }
        self.completion = completion
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.finish(with: nil)
        }
    }

    private func finish(with fix: FreshFix?) {
        guard let completion else { return }
        self.completion = nil
        completion(fix)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { finish(with: nil); return }
        finish(with: FreshFix(userLat: loc.coordinate.latitude,
                              userLng: loc.coordinate.longitude,
                              accuracyMeters: loc.horizontalAccuracy,
                              course: loc.course,
                              timestamp: loc.timestamp))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: nil)
    }
}

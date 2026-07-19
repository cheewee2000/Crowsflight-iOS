// CrowsflightWatch Watch App/WatchDestinationStore.swift
//
// Receives the destination list from the phone (applicationContext) and caches
// the raw payload in UserDefaults so the watch works standalone/offline.

import Combine
import Foundation
import WatchConnectivity

final class WatchDestinationStore: NSObject, ObservableObject, WCSessionDelegate {

    @Published private(set) var destinations: [WatchSyncPayload.Destination] = []
    @Published private(set) var units: String = "m"

    private static let cacheKey = "watchSyncPayload"
    private var lastTimestamp: Date = .distantPast

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey),
           let payload = WatchSyncPayload.decode(data) {
            apply(payload)
        }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    /// Latest-wins by payload timestamp (cache vs. session-delivered context).
    private func apply(_ payload: WatchSyncPayload) {
        guard payload.timestamp >= lastTimestamp else { return }
        lastTimestamp = payload.timestamp
        destinations = payload.destinations
        units = payload.units
    }

    private func handle(context: [String: Any]) {
        guard let data = context["payload"] as? Data,
              let payload = WatchSyncPayload.decode(data) else { return }
        DispatchQueue.main.async {
            self.apply(payload)
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        handle(context: session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handle(context: applicationContext)
    }
}

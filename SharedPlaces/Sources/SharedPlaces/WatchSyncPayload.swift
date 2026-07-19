// SharedPlaces/Sources/SharedPlaces/WatchSyncPayload.swift
import Foundation

/// Destination list the phone pushes to the watch via
/// WCSession.updateApplicationContext (as Data under the "payload" key).
/// Default JSONEncoder/JSONDecoder settings on both sides.
public struct WatchSyncPayload: Codable, Equatable {

    public struct Destination: Codable, Equatable {
        public var name: String
        public var lat: Double
        public var lng: Double

        public init(name: String, lat: Double, lng: Double) {
            self.name = name
            self.lat = lat
            self.lng = lng
        }
    }

    public var version: Int
    public var destinations: [Destination]
    public var units: String
    public var timestamp: Date

    public init(destinations: [Destination], units: String, timestamp: Date, version: Int = 1) {
        self.version = version
        self.destinations = destinations
        self.units = units
        self.timestamp = timestamp
    }

    public func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func decode(_ data: Data) -> WatchSyncPayload? {
        try? JSONDecoder().decode(WatchSyncPayload.self, from: data)
    }
}

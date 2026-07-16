import Foundation

public struct WidgetSnapshot: Codable, Equatable {
    public var destinationName: String
    public var destLat: Double
    public var destLng: Double
    public var destinationIndex: Int
    public var destinationCount: Int
    public var userLat: Double
    public var userLng: Double
    public var accuracyMeters: Double
    public var units: String
    /// Course over ground in degrees from north; < 0 when invalid (stationary/unknown).
    public var course: Double
    public var timestamp: Date

    public init(destinationName: String, destLat: Double, destLng: Double,
                destinationIndex: Int, destinationCount: Int,
                userLat: Double, userLng: Double, accuracyMeters: Double,
                units: String, course: Double, timestamp: Date) {
        self.destinationName = destinationName
        self.destLat = destLat
        self.destLng = destLng
        self.destinationIndex = destinationIndex
        self.destinationCount = destinationCount
        self.userLat = userLat
        self.userLng = userLng
        self.accuracyMeters = accuracyMeters
        self.units = units
        self.course = course
        self.timestamp = timestamp
    }
}

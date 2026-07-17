import Foundation

/// A user-location fix the widget fetched itself (one-shot CLLocationManager
/// request inside the timeline provider), as opposed to the fix the app
/// persisted in the snapshot.
public struct FreshFix: Equatable {
    public var userLat: Double
    public var userLng: Double
    public var accuracyMeters: Double
    /// Course over ground in degrees from north; < 0 when invalid (stationary/unknown).
    public var course: Double
    public var timestamp: Date

    public init(userLat: Double, userLng: Double, accuracyMeters: Double,
                course: Double, timestamp: Date) {
        self.userLat = userLat
        self.userLng = userLng
        self.accuracyMeters = accuracyMeters
        self.course = course
        self.timestamp = timestamp
    }
}

/// The effective fix to render, after merging the snapshot with an optional
/// widget-fetched fix. Fields mirror the makeRenderModel parameters they feed.
public struct ResolvedFix: Equatable {
    public var userLat: Double
    public var userLng: Double
    public var accuracyMeters: Double
    public var course: Double
    public var heading: Double
    public var timestamp: Date
}

/// Merge the app snapshot with a widget-fetched fix.
///
/// The fresh fix wins only when it is actually newer than the snapshot (the
/// system may hand the widget a cached location older than what the app saw).
/// When the fresh fix wins: a valid course (moving) drives the dial, so the
/// inherited app heading is dropped (-1); with no course (stationary) the
/// inherited heading is kept — same dial behavior as before.
public func resolveFix(snapshot: WidgetSnapshot, fresh: FreshFix?) -> ResolvedFix {
    guard let fresh, fresh.timestamp > snapshot.timestamp else {
        return ResolvedFix(userLat: snapshot.userLat, userLng: snapshot.userLng,
                           accuracyMeters: snapshot.accuracyMeters,
                           course: snapshot.course, heading: snapshot.heading,
                           timestamp: snapshot.timestamp)
    }
    let moving = fresh.course >= 0
    return ResolvedFix(userLat: fresh.userLat, userLng: fresh.userLng,
                       accuracyMeters: fresh.accuracyMeters,
                       course: moving ? fresh.course : snapshot.course,
                       heading: moving ? -1 : snapshot.heading,
                       timestamp: fresh.timestamp)
}

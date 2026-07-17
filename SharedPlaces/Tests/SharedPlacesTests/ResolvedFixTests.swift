import XCTest
@testable import SharedPlaces

final class ResolvedFixTests: XCTestCase {

    let t0 = Date(timeIntervalSince1970: 1_000_000)

    func snapshot(heading: Double = 80) -> WidgetSnapshot {
        WidgetSnapshot(destinationName: "Home", destLat: 40.7, destLng: -74.0,
                       destinationIndex: 0, destinationCount: 3,
                       userLat: 40.68, userLng: -73.98, accuracyMeters: 12,
                       units: "m", course: 45, heading: heading, timestamp: t0)
    }

    // MARK: - No fresh fix → snapshot passthrough

    func testNoFreshFixUsesSnapshotValues() {
        let r = resolveFix(snapshot: snapshot(), fresh: nil)
        XCTAssertEqual(r.userLat, 40.68)
        XCTAssertEqual(r.userLng, -73.98)
        XCTAssertEqual(r.accuracyMeters, 12)
        XCTAssertEqual(r.course, 45)
        XCTAssertEqual(r.heading, 80)
        XCTAssertEqual(r.timestamp, t0)
    }

    // MARK: - Fresh fix newer than snapshot → position/accuracy/timestamp from fresh

    func testNewerFreshFixReplacesPosition() {
        let fresh = FreshFix(userLat: 40.60, userLng: -73.90, accuracyMeters: 35,
                             course: -1, timestamp: t0.addingTimeInterval(600))
        let r = resolveFix(snapshot: snapshot(), fresh: fresh)
        XCTAssertEqual(r.userLat, 40.60)
        XCTAssertEqual(r.userLng, -73.90)
        XCTAssertEqual(r.accuracyMeters, 35)
        XCTAssertEqual(r.timestamp, t0.addingTimeInterval(600))
    }

    func testNewerFreshFixWithoutCourseKeepsInheritedHeading() {
        // Stationary fresh fix (course invalid): the dial keeps the heading the
        // app last saw, matching the existing inherit-heading behavior.
        let fresh = FreshFix(userLat: 40.60, userLng: -73.90, accuracyMeters: 35,
                             course: -1, timestamp: t0.addingTimeInterval(600))
        let r = resolveFix(snapshot: snapshot(heading: 80), fresh: fresh)
        XCTAssertEqual(r.course, 45)
        XCTAssertEqual(r.heading, 80)
    }

    func testNewerFreshFixWithValidCourseDrivesDial() {
        // Moving fresh fix: travel direction beats the stale app heading.
        // heading must come back invalid (-1) so makeRenderModel falls through
        // to course.
        let fresh = FreshFix(userLat: 40.60, userLng: -73.90, accuracyMeters: 35,
                             course: 200, timestamp: t0.addingTimeInterval(600))
        let r = resolveFix(snapshot: snapshot(heading: 80), fresh: fresh)
        XCTAssertEqual(r.course, 200)
        XCTAssertEqual(r.heading, -1)
    }

    // MARK: - Fresh fix older than snapshot (cached system fix) → snapshot wins

    func testStaleFreshFixIgnored() {
        let fresh = FreshFix(userLat: 40.60, userLng: -73.90, accuracyMeters: 35,
                             course: 200, timestamp: t0.addingTimeInterval(-600))
        let r = resolveFix(snapshot: snapshot(), fresh: fresh)
        XCTAssertEqual(r.userLat, 40.68)
        XCTAssertEqual(r.userLng, -73.98)
        XCTAssertEqual(r.accuracyMeters, 12)
        XCTAssertEqual(r.course, 45)
        XCTAssertEqual(r.heading, 80)
        XCTAssertEqual(r.timestamp, t0)
    }

    // MARK: - Composition with makeRenderModel

    func testResolvedFreshFixFeedsRenderModel() {
        // End-to-end: fresh fix, no course → distance recomputed from fresh
        // position, dial up = inherited heading, not stale.
        let snap = snapshot(heading: 80)
        let fresh = FreshFix(userLat: 40.69, userLng: -73.99, accuracyMeters: 8,
                             course: -1, timestamp: t0.addingTimeInterval(900))
        let r = resolveFix(snapshot: snap, fresh: fresh)
        let model = makeRenderModel(
            destinationName: snap.destinationName,
            destinationIndex: snap.destinationIndex,
            destinationCount: snap.destinationCount,
            destLat: snap.destLat, destLng: snap.destLng,
            userLat: r.userLat, userLng: r.userLng, accuracyMeters: r.accuracyMeters,
            units: snap.units, course: r.course, heading: r.heading,
            fixTimestamp: r.timestamp, now: t0.addingTimeInterval(960),
            staleThreshold: 30 * 60)
        XCTAssertEqual(model.headingDegrees, 80)
        XCTAssertFalse(model.isStale)
        let expected = CrowsflightGeo.distanceMeters(userLat: 40.69, userLng: -73.99,
                                                     destLat: 40.7, destLng: -74.0)
        let expectedText = CrowsflightGeo.distanceText(distanceMeters: expected, units: "m")
        XCTAssertEqual(model.distanceValue, expectedText.value)
    }
}

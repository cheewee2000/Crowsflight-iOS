import XCTest
import CoreLocation
@testable import SharedPlaces

final class CrowsflightGeoTests: XCTestCase {

    func testDistanceMatchesCoreLocation() {
        let d = CrowsflightGeo.distanceMeters(userLat: 40.7128, userLng: -74.0060,
                                              destLat: 40.6892, destLng: -74.0445)
        let expected = CLLocation(latitude: 40.7128, longitude: -74.0060)
            .distance(from: CLLocation(latitude: 40.6892, longitude: -74.0445))
        XCTAssertEqual(d, expected, accuracy: 0.001)
    }

    func testBearingDueEastIsNinety() {
        // Same latitude, destination to the east → ~90°.
        let b = CrowsflightGeo.bearingDegrees(userLat: 0, userLng: 0, destLat: 0, destLng: 1)
        XCTAssertEqual(b, 90, accuracy: 0.5)
    }

    func testBearingDueNorthIsZero() {
        let b = CrowsflightGeo.bearingDegrees(userLat: 0, userLng: 0, destLat: 1, destLng: 0)
        XCTAssertEqual(b, 0, accuracy: 0.5)
    }

    func testArcProgressMatchesFormulaAndClamps() {
        // 3701 m → ~104 per the app formula.
        XCTAssertEqual(CrowsflightGeo.arcProgress(distanceMeters: 3701), 104, accuracy: 1.0)
        // Tiny distance clamps to the 5 floor.
        XCTAssertEqual(CrowsflightGeo.arcProgress(distanceMeters: 1), 5, accuracy: 0.0001)
        // Very large distance → ~259 per the formula (asymptotic, does not reach 359).
        XCTAssertEqual(CrowsflightGeo.arcProgress(distanceMeters: 5_000_000), 259, accuracy: 1.0)
        // Astronomically large distance hits the 359 ceiling clamp.
        XCTAssertEqual(CrowsflightGeo.arcProgress(distanceMeters: 1_000_000_000), 359, accuracy: 0.0001)
    }

    func testSweptIsThreeSixtyMinusProgress() {
        XCTAssertEqual(CrowsflightGeo.sweptDegrees(progress: 104), 256, accuracy: 0.0001)
    }

    func testSpreadClampsBetweenSixAndNinety() {
        // Far + accurate → narrow, floored at 6.
        XCTAssertEqual(CrowsflightGeo.spreadDegrees(distanceMeters: 100_000, accuracyMeters: 5), 6, accuracy: 0.0001)
        // At the destination → wide, capped at 90.
        XCTAssertEqual(CrowsflightGeo.spreadDegrees(distanceMeters: 0, accuracyMeters: 5), 90, accuracy: 0.0001)
    }

    func testDistanceTextImperial() {
        let far = CrowsflightGeo.distanceText(distanceMeters: 3701, units: "m")
        XCTAssertEqual(far.value, "2.30"); XCTAssertEqual(far.unit, "MILES")
        let near = CrowsflightGeo.distanceText(distanceMeters: 100, units: "m")
        XCTAssertEqual(near.value, "328"); XCTAssertEqual(near.unit, "FEET")
    }

    func testDistanceTextMetric() {
        let far = CrowsflightGeo.distanceText(distanceMeters: 3701, units: "km")
        XCTAssertEqual(far.value, "3.70"); XCTAssertEqual(far.unit, "KM")
        let near = CrowsflightGeo.distanceText(distanceMeters: 500, units: "km")
        XCTAssertEqual(near.value, "500"); XCTAssertEqual(near.unit, "METERS")
    }

    func testAccuracyText() {
        XCTAssertEqual(CrowsflightGeo.accuracyText(accuracyMeters: 14.6, units: "m"), "± 47'")
        XCTAssertEqual(CrowsflightGeo.accuracyText(accuracyMeters: 14.6, units: "km"), "± 14m")
    }

    func testMakeRenderModelStaleFlag() {
        let fresh = makeRenderModel(destinationName: "Home", destinationIndex: 0, destinationCount: 5,
            destLat: 40.6892, destLng: -74.0445, userLat: 40.7128, userLng: -74.0060,
            accuracyMeters: 14.6, units: "m",
            fixTimestamp: Date(timeIntervalSince1970: 1000),
            now: Date(timeIntervalSince1970: 1000 + 60), staleThreshold: 30 * 60)
        XCTAssertFalse(fresh.isStale)
        XCTAssertEqual(fresh.pageText, "1/5")

        let stale = makeRenderModel(destinationName: "Home", destinationIndex: 0, destinationCount: 5,
            destLat: 40.6892, destLng: -74.0445, userLat: 40.7128, userLng: -74.0060,
            accuracyMeters: 14.6, units: "m",
            fixTimestamp: Date(timeIntervalSince1970: 1000),
            now: Date(timeIntervalSince1970: 1000 + 31 * 60), staleThreshold: 30 * 60)
        XCTAssertTrue(stale.isStale)
    }
}

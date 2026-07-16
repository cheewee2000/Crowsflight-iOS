import XCTest
@testable import SharedPlaces

final class WidgetSnapshotStoreTests: XCTestCase {
    func testSnapshotCodableRoundTrip() throws {
        let snap = WidgetSnapshot(
            destinationName: "Home", destLat: 40.681, destLng: -73.95,
            destinationIndex: 0, destinationCount: 5,
            userLat: 40.71, userLng: -74.0, accuracyMeters: 14.6,
            units: "m", timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(snap)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        XCTAssertEqual(decoded, snap)
    }
}

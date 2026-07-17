import XCTest
@testable import SharedPlaces

final class WidgetSnapshotStoreTests: XCTestCase {
    func testSnapshotCodableRoundTrip() throws {
        let snap = WidgetSnapshot(
            destinationName: "Home", destLat: 40.681, destLng: -73.95,
            destinationIndex: 0, destinationCount: 5,
            userLat: 40.71, userLng: -74.0, accuracyMeters: 14.6,
            units: "m", course: -1, timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(snap)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        XCTAssertEqual(decoded, snap)
    }
}

extension WidgetSnapshotStoreTests {
    func testWriteThenReadReturnsEqualSnapshot() throws {
        let defaults = UserDefaults(suiteName: "test.crowsflight.widget")!
        defaults.removePersistentDomain(forName: "test.crowsflight.widget")
        let snap = WidgetSnapshot(
            destinationName: "Studio", destLat: 40.7, destLng: -73.9,
            destinationIndex: 2, destinationCount: 4,
            userLat: 40.71, userLng: -74.0, accuracyMeters: 9.0,
            units: "m", course: -1, timestamp: Date(timeIntervalSince1970: 1_700_000_000))
        WidgetSnapshotStore.write(snap, to: defaults)
        XCTAssertEqual(WidgetSnapshotStore.read(from: defaults), snap)
    }

    func testReadReturnsNilWhenEmpty() {
        let defaults = UserDefaults(suiteName: "test.crowsflight.empty")!
        defaults.removePersistentDomain(forName: "test.crowsflight.empty")
        XCTAssertNil(WidgetSnapshotStore.read(from: defaults))
    }

    func testSnapshotPreservesHeadingThroughStore() throws {
        let defaults = UserDefaults(suiteName: "test.crowsflight.heading")!
        defaults.removePersistentDomain(forName: "test.crowsflight.heading")
        let snap = WidgetSnapshot(
            destinationName: "Home", destLat: 40.681, destLng: -73.95,
            destinationIndex: 0, destinationCount: 5,
            userLat: 40.71, userLng: -74.0, accuracyMeters: 14.6,
            units: "m", course: 12, heading: 250,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000))
        WidgetSnapshotStore.write(snap, to: defaults)
        XCTAssertEqual(WidgetSnapshotStore.read(from: defaults)?.heading, 250)
    }
}

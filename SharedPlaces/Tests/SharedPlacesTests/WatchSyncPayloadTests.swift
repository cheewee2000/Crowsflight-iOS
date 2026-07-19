// SharedPlaces/Tests/SharedPlacesTests/WatchSyncPayloadTests.swift
import XCTest
@testable import SharedPlaces

final class WatchSyncPayloadTests: XCTestCase {

    let t0 = Date(timeIntervalSince1970: 1_000_000)

    func testRoundTrip() throws {
        let payload = WatchSyncPayload(
            destinations: [.init(name: "Home", lat: 40.7, lng: -74.0),
                           .init(name: "Studio", lat: 40.69, lng: -73.99)],
            units: "m", timestamp: t0)
        let decoded = WatchSyncPayload.decode(try payload.encoded())
        XCTAssertEqual(decoded, payload)
        XCTAssertEqual(decoded?.version, 1)
    }

    func testEmptyListRoundTrip() throws {
        let payload = WatchSyncPayload(destinations: [], units: "km", timestamp: t0)
        XCTAssertEqual(WatchSyncPayload.decode(try payload.encoded()), payload)
    }

    func testDecodeGarbageReturnsNil() {
        XCTAssertNil(WatchSyncPayload.decode(Data([0x00, 0x01, 0x02])))
        XCTAssertNil(WatchSyncPayload.decode(Data("{}".utf8)))
    }
}

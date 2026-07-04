import XCTest
@testable import SharedPlaces

final class PlaceURLParserTests: XCTestCase {

    // MARK: extractURL

    func testExtractsURLFromGoogleShareText() {
        let text = "Fort Greene Park\nhttps://maps.app.goo.gl/AbC123xyz"
        XCTAssertEqual(PlaceURLParser.extractURL(from: text)?.host, "maps.app.goo.gl")
    }

    func testExtractURLReturnsNilForPlainText() {
        XCTAssertNil(PlaceURLParser.extractURL(from: "just some words, no link"))
    }

    // MARK: isShortLink

    func testShortLinkHosts() {
        XCTAssertTrue(PlaceURLParser.isShortLink(URL(string: "https://maps.app.goo.gl/AbC")!))
        XCTAssertTrue(PlaceURLParser.isShortLink(URL(string: "https://goo.gl/maps/AbC")!))
        XCTAssertTrue(PlaceURLParser.isShortLink(URL(string: "https://share.google/xyz")!))
        XCTAssertFalse(PlaceURLParser.isShortLink(URL(string: "https://www.google.com/maps/place/X")!))
        XCTAssertFalse(PlaceURLParser.isShortLink(URL(string: "https://maps.apple.com/?ll=1,2")!))
    }

    // MARK: Google full URLs

    func testGooglePlaceURLPrefersPinCoordsOverViewport() {
        // !3d!4d is the place pin; @lat,lng is only the viewport center
        let url = URL(string: "https://www.google.com/maps/place/Fort+Greene+Park/@40.6905615,-73.9762079,17z/data=!3m1!4b1!4m6!3m5!1s0x89c25b:0x3544!8m2!3d40.6913984!4d-73.9755405!16zL20vMDJyNXFz")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.name, "Fort Greene Park")
        XCTAssertEqual(p?.lat ?? 0, 40.6913984, accuracy: 1e-7)
        XCTAssertEqual(p?.lng ?? 0, -73.9755405, accuracy: 1e-7)
    }

    func testGooglePlaceURLFallsBackToViewportCoords() {
        let url = URL(string: "https://www.google.com/maps/place/Fort+Greene+Park/@40.6905615,-73.9762079,17z")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.name, "Fort Greene Park")
        XCTAssertEqual(p?.lat ?? 0, 40.6905615, accuracy: 1e-7)
        XCTAssertEqual(p?.lng ?? 0, -73.9762079, accuracy: 1e-7)
    }

    func testGoogleQueryCoordinateURL() {
        let url = URL(string: "https://maps.google.com/?q=40.691398,-73.975540")!
        let p = PlaceURLParser.parse(url, sharedText: "Fort Greene Park\nhttps://maps.google.com/?q=40.691398,-73.975540")
        XCTAssertEqual(p?.lat ?? 0, 40.691398, accuracy: 1e-6)
        XCTAssertEqual(p?.lng ?? 0, -73.975540, accuracy: 1e-6)
        XCTAssertEqual(p?.name, "Fort Greene Park") // from shared text
    }

    func testGoogleSearchAPIURL() {
        let url = URL(string: "https://www.google.com/maps/search/?api=1&query=40.691398%2C-73.975540")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.lat ?? 0, 40.691398, accuracy: 1e-6)
        XCTAssertEqual(p?.lng ?? 0, -73.975540, accuracy: 1e-6)
    }

    func testGoogleSearchPathCoordinateURL() {
        // What maps.app.goo.gl short links from the iOS app's share button (entry=tts)
        // expand to: coordinates in the path, ",+" separated, nothing in the query.
        let url = URL(string: "https://www.google.com/maps/search/-33.918017,+18.430922?entry=tts&ucbcb=1")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.lat ?? 0, -33.918017, accuracy: 1e-6)
        XCTAssertEqual(p?.lng ?? 0, 18.430922, accuracy: 1e-6)
    }

    func testGoogleConsentInterstitialUnwrapsContinueURL() {
        // In the EU, short-link expansion lands on consent.google.com with the real
        // maps URL (once-encoded) in ?continue=. Captured from a live device share.
        let url = URL(string: "https://consent.google.com/ml?continue=https://maps.google.com/maps?q%3DCentral%2BMarket,%2BAdami%25C4%258D-Lundrovo%2Bnabre%25C5%25BEje%2B6,%2B1000%2BLjubljana,%2BSlovenia%26ftid%3D0x47652d62d01c6f81:0x70682918d39c1781%26entry%3Dgps&gl=SI&m=0&pc=m&hl=en")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.name, "Central Market, Adamič-Lundrovo nabrežje 6, 1000 Ljubljana, Slovenia")
    }

    func testGoogleTextQueryGivesNameWithoutCoords() {
        let url = URL(string: "https://maps.google.com/?q=Fort+Greene+Park")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.name, "Fort Greene Park")
        XCTAssertEqual(p?.coordinatesValid, false)
    }

    // MARK: Apple Maps URLs

    func testAppleMapsLLAndQ() {
        let url = URL(string: "https://maps.apple.com/?ll=40.691398,-73.975540&q=Fort%20Greene%20Park")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.name, "Fort Greene Park")
        XCTAssertEqual(p?.lat ?? 0, 40.691398, accuracy: 1e-6)
        XCTAssertEqual(p?.lng ?? 0, -73.975540, accuracy: 1e-6)
    }

    func testAppleMapsCoordinateAndName() {
        let url = URL(string: "https://maps.apple.com/place?coordinate=40.691398,-73.975540&name=Fort%20Greene%20Park")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.name, "Fort Greene Park")
        XCTAssertEqual(p?.coordinatesValid, true)
    }

    func testAppleMapsAddressBecomesAddressField() {
        let url = URL(string: "https://maps.apple.com/?address=1%20Main%20St%20Brooklyn&ll=40.7,-73.99&q=Home")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.address, "1 Main St Brooklyn")
        XCTAssertEqual(p?.name, "Home")
    }

    // MARK: validation

    func testRejectsZeroZeroCoordinates() {
        XCTAssertFalse(ParsedPlace.valid(lat: 0, lng: 0))
        let url = URL(string: "https://maps.google.com/?q=0,0")!
        XCTAssertEqual(PlaceURLParser.parse(url, sharedText: nil)?.coordinatesValid, false)
    }

    func testRejectsOutOfRangeCoordinates() {
        XCTAssertFalse(ParsedPlace.valid(lat: 91, lng: 0.1))
        XCTAssertFalse(ParsedPlace.valid(lat: 40, lng: 181))
        XCTAssertTrue(ParsedPlace.valid(lat: -89.9, lng: 179.9))
    }

    func testNonMapsURLReturnsNil() {
        XCTAssertNil(PlaceURLParser.parse(URL(string: "https://example.com/foo?q=1,2")!, sharedText: nil))
    }

    func testShortLinkHostsGcoAndMapsApple() {
        XCTAssertTrue(PlaceURLParser.isShortLink(URL(string: "https://g.co/kgs/AbC")!))
        XCTAssertTrue(PlaceURLParser.isShortLink(URL(string: "https://maps.apple/p/XyZ")!))
    }

    func testAppleMapsAddressOnlyFallsBackToAddressAsName() {
        let url = URL(string: "https://maps.apple.com/?address=100%20Main%20St&ll=40.7,-73.99")!
        let p = PlaceURLParser.parse(url, sharedText: nil)
        XCTAssertEqual(p?.name, "100 Main St")
        XCTAssertEqual(p?.address, "100 Main St")
    }

    func testGoogleLookalikeHostRejected() {
        XCTAssertNil(PlaceURLParser.parse(URL(string: "https://maps.google.evil.example/?q=1,2")!, sharedText: nil))
    }

    // MARK: nameFromSharedText

    func testNameFromSharedTextStripsURLAndTrims() {
        XCTAssertEqual(PlaceURLParser.nameFromSharedText("Fort Greene Park\nhttps://maps.app.goo.gl/AbC"),
                       "Fort Greene Park")
        XCTAssertNil(PlaceURLParser.nameFromSharedText("https://maps.app.goo.gl/AbC"))
    }
}

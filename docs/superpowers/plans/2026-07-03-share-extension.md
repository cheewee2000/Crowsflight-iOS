# "Share to Crowsflight" Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Share a single place from Google Maps or Apple Maps into Crowsflight; it's appended to the saved list and becomes the current destination.

**Architecture:** A Swift share extension resolves the shared URL to `{name, lat, lng}` and drops it in an App Group `NSUserDefaults` inbox; the ObjC main app drains the inbox on `applicationDidBecomeActive` through the existing `addNewDestination:newlat:newlng:` path. URL parsing lives in a standalone SPM package (`SharedPlaces`) so it's testable with `swift test`; its source files are also compiled directly into the extension target.

**Tech Stack:** Swift 5 (extension + parser), Objective-C (app delegate ingestion), Ruby `xcodeproj` gem (adds the extension target to the 2013-era project file), XCTest via SPM.

**Spec:** `docs/superpowers/specs/2026-07-03-share-extension-design.md`

## Global Constraints

- App Group ID: `group.com.cwandt.crowsflight` (already present in `Crowsflight/Crowsflight.entitlements`)
- Inbox key in the shared suite: `pendingImports`
- Main app bundle ID: `com.cwandt.crowsflight`; extension bundle ID: `com.cwandt.crowsflight.share`
- Development team: `L6DVQR8JB9`; code sign style: Automatic
- Deployment target: iOS 14.0; `SWIFT_VERSION = 5.0`
- Saved-place dictionary shape (must match app schema exactly): keys `searchedText` (String, never empty), `address` (String, `""` if unknown), `lat` (NSNumber), `lng` (NSNumber)
- Reject coordinates that are exactly (0,0) or out of range (|lat| > 90, |lng| > 180)
- All git commands run from repo root: `/Users/cwwang/CW&T Dropbox/Che-Wei Wang/My Mac (9.local)/Desktop/Crowsflight iOS/Crowsflight-iOS`
- Never write an inbox entry without a non-empty `searchedText` (the Watch parser force-unwraps it)

---

### Task 1: `SharedPlaces` package — URL parsing (pure, tested)

**Files:**
- Create: `SharedPlaces/Package.swift`
- Create: `SharedPlaces/Sources/SharedPlaces/PlaceURLParser.swift`
- Test: `SharedPlaces/Tests/SharedPlacesTests/PlaceURLParserTests.swift`

**Interfaces:**
- Consumes: nothing (Foundation only — no CoreLocation, no networking, so tests run offline on macOS).
- Produces (used verbatim by Task 2's `ShareViewController`):
  - `struct ParsedPlace { var name: String?; var address: String?; var lat: Double?; var lng: Double?; var coordinatesValid: Bool; static func valid(lat: Double, lng: Double) -> Bool }`
  - `enum PlaceURLParser`:
    - `static func extractURL(from text: String) -> URL?`
    - `static func isShortLink(_ url: URL) -> Bool`
    - `static func parse(_ url: URL, sharedText: String?) -> ParsedPlace?` — pure, no network; returns `nil` for non-maps URLs or when neither name nor coordinates found.
    - `static func nameFromSharedText(_ text: String) -> String?`

- [ ] **Step 1: Create the package manifest**

`SharedPlaces/Package.swift`:

```swift
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SharedPlaces",
    platforms: [.iOS(.v14), .macOS(.v12)],
    products: [
        .library(name: "SharedPlaces", targets: ["SharedPlaces"])
    ],
    targets: [
        .target(name: "SharedPlaces"),
        .testTarget(name: "SharedPlacesTests", dependencies: ["SharedPlaces"])
    ]
)
```

- [ ] **Step 2: Write the failing tests**

`SharedPlaces/Tests/SharedPlacesTests/PlaceURLParserTests.swift`:

```swift
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

    // MARK: nameFromSharedText

    func testNameFromSharedTextStripsURLAndTrims() {
        XCTAssertEqual(PlaceURLParser.nameFromSharedText("Fort Greene Park\nhttps://maps.app.goo.gl/AbC"),
                       "Fort Greene Park")
        XCTAssertNil(PlaceURLParser.nameFromSharedText("https://maps.app.goo.gl/AbC"))
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd SharedPlaces && swift test 2>&1 | tail -20`
Expected: build error — `PlaceURLParser` / `ParsedPlace` not defined.

- [ ] **Step 4: Implement the parser**

`SharedPlaces/Sources/SharedPlaces/PlaceURLParser.swift`:

```swift
import Foundation

public struct ParsedPlace: Equatable {
    public var name: String?
    public var address: String?
    public var lat: Double?
    public var lng: Double?

    public var coordinatesValid: Bool {
        guard let lat = lat, let lng = lng else { return false }
        return ParsedPlace.valid(lat: lat, lng: lng)
    }

    /// Rejects the (0,0) Google export/redirect bug and out-of-range values.
    public static func valid(lat: Double, lng: Double) -> Bool {
        if lat == 0 && lng == 0 { return false }
        return abs(lat) <= 90 && abs(lng) <= 180
    }

    public init(name: String? = nil, address: String? = nil, lat: Double? = nil, lng: Double? = nil) {
        self.name = name
        self.address = address
        self.lat = lat
        self.lng = lng
    }
}

public enum PlaceURLParser {

    public static func extractURL(from text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, options: [], range: range)
            .compactMap { $0.url }
            .first { $0.scheme == "http" || $0.scheme == "https" }
    }

    public static func isShortLink(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "maps.app.goo.gl" || host == "goo.gl" || host == "g.co" || host == "share.google"
    }

    public static func parse(_ url: URL, sharedText: String?) -> ParsedPlace? {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = comps.host?.lowercased() else { return nil }

        var place: ParsedPlace
        if host.contains("google.") || host.hasPrefix("google") {
            place = parseGoogle(url: url, comps: comps)
        } else if host == "maps.apple.com" {
            place = parseApple(comps: comps)
        } else {
            return nil
        }

        if (place.name ?? "").isEmpty, let text = sharedText {
            place.name = nameFromSharedText(text)
        }
        if (place.name ?? "").isEmpty && place.lat == nil { return nil }
        return place
    }

    /// The non-URL remainder of shared text like "Fort Greene Park\nhttps://maps.app.goo.gl/x".
    public static func nameFromSharedText(_ text: String) -> String? {
        var stripped = text
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let range = NSRange(text.startIndex..., in: text)
            for match in detector.matches(in: text, options: [], range: range).reversed() {
                if let r = Range(match.range, in: stripped) {
                    stripped.removeSubrange(r)
                }
            }
        }
        let trimmed = stripped.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Google

    private static func parseGoogle(url: URL, comps: URLComponents) -> ParsedPlace {
        var place = ParsedPlace()
        let s = url.absoluteString

        // Name from /maps/place/<name>/ (pathComponents is already percent-decoded)
        let parts = url.pathComponents
        if let i = parts.firstIndex(of: "place"), i + 1 < parts.count {
            place.name = parts[i + 1].replacingOccurrences(of: "+", with: " ")
        }

        // Coordinates, best source first:
        // 1. !3d<lat>!4d<lng> — the place pin (take the LAST occurrence in the data blob)
        // 2. q= / query= containing "lat,lng"
        // 3. @lat,lng — viewport center
        if let m = matches(of: "!3d(-?[0-9]+\\.?[0-9]*)!4d(-?[0-9]+\\.?[0-9]*)", in: s).last {
            place.lat = Double(m[1])
            place.lng = Double(m[2])
        } else if let ll = latLngPair(queryValue(comps, "q") ?? queryValue(comps, "query")) {
            place.lat = ll.0
            place.lng = ll.1
        } else if let m = matches(of: "@(-?[0-9]+\\.?[0-9]*),(-?[0-9]+\\.?[0-9]*)", in: s).first {
            place.lat = Double(m[1])
            place.lng = Double(m[2])
        }

        // q= as a text query is the name
        if (place.name ?? "").isEmpty,
           let q = queryValue(comps, "q") ?? queryValue(comps, "query"),
           latLngPair(q) == nil {
            place.name = q.replacingOccurrences(of: "+", with: " ")
        }
        return place
    }

    // MARK: - Apple

    private static func parseApple(comps: URLComponents) -> ParsedPlace {
        var place = ParsedPlace()
        if let ll = latLngPair(queryValue(comps, "ll")) ?? latLngPair(queryValue(comps, "coordinate")) {
            place.lat = ll.0
            place.lng = ll.1
        }
        let q = queryValue(comps, "q")
        place.name = queryValue(comps, "name")
            ?? (latLngPair(q) == nil ? q : nil)
            ?? queryValue(comps, "address")
        place.address = queryValue(comps, "address")
        return place
    }

    // MARK: - Helpers

    private static func queryValue(_ comps: URLComponents, _ name: String) -> String? {
        comps.queryItems?.first { $0.name == name }?.value
    }

    private static func latLngPair(_ s: String?) -> (Double, Double)? {
        guard let s = s else { return nil }
        let parts = s.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count >= 2, let lat = parts[0], let lng = parts[1] else { return nil }
        return (lat, lng)
    }

    /// All regex matches; each element is [wholeMatch, group1, group2, ...].
    private static func matches(of pattern: String, in s: String) -> [[String]] {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = s as NSString
        return re.matches(in: s, range: NSRange(location: 0, length: ns.length)).map { m in
            (0..<m.numberOfRanges).map { i in
                m.range(at: i).location == NSNotFound ? "" : ns.substring(with: m.range(at: i))
            }
        }
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd SharedPlaces && swift test 2>&1 | tail -5`
Expected: `Test Suite 'All tests' passed` with 15 tests, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add SharedPlaces
git commit -m "feat: add SharedPlaces package with maps URL parser"
```

---

### Task 2: Share extension target

**Files:**
- Create: `CrowsflightShare/ShareViewController.swift`
- Create: `CrowsflightShare/Info.plist`
- Create: `CrowsflightShare/CrowsflightShare.entitlements`
- Create: `scripts/add_share_extension.rb`
- Modify: `Crowsflight.xcodeproj/project.pbxproj` (via the script only — never by hand)

**Interfaces:**
- Consumes: `PlaceURLParser.extractURL(from:)`, `.isShortLink(_:)`, `.parse(_:sharedText:)`, `.nameFromSharedText(_:)`, `ParsedPlace` (Task 1). The parser source file is compiled directly into this target, so no `import SharedPlaces`.
- Produces: entries appended to the App Group inbox — `UserDefaults(suiteName: "group.com.cwandt.crowsflight")`, key `pendingImports`, value `[[String: Any]]` where each dict is `{"searchedText": String, "address": String, "lat": NSNumber(Double), "lng": NSNumber(Double)}` (Task 3 reads exactly this).

- [ ] **Step 1: Write the extension Info.plist**

`CrowsflightShare/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Crowsflight</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>NSExtensionActivationRule</key>
            <dict>
                <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
                <integer>1</integer>
                <key>NSExtensionActivationSupportsText</key>
                <true/>
            </dict>
        </dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.share-services</string>
        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
    </dict>
</dict>
</plist>
```

- [ ] **Step 2: Write the extension entitlements**

`CrowsflightShare/CrowsflightShare.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.cwandt.crowsflight</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: Write ShareViewController**

`CrowsflightShare/ShareViewController.swift`:

```swift
import UIKit
import CoreLocation
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private let appGroupID = "group.com.cwandt.crowsflight"
    private let pendingImportsKey = "pendingImports"

    private let card = UIView()
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let cancelButton = UIButton(type: .system)
    private let geocoder = CLGeocoder()

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        resolveSharedItem()
    }

    // MARK: - UI

    private func buildUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)

        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 14
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        statusLabel.text = "Reading location…"
        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(statusLabel)

        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(spinner)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.isHidden = true
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 280),
            statusLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            statusLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            spinner.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            spinner.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            cancelButton.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 8),
            cancelButton.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(
            domain: "com.cwandt.crowsflight.share", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Cancelled"]))
    }

    // MARK: - Resolution pipeline

    private func resolveSharedItem() {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .flatMap { $0.attachments ?? [] } ?? []

        if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            p.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
                DispatchQueue.main.async { self?.handle(url: item as? URL, text: nil) }
            }
        } else if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            p.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, _ in
                let text = item as? String
                DispatchQueue.main.async {
                    self?.handle(url: text.flatMap { PlaceURLParser.extractURL(from: $0) }, text: text)
                }
            }
        } else {
            fail()
        }
    }

    private func handle(url: URL?, text: String?) {
        guard let url = url else { return fail() }
        if PlaceURLParser.isShortLink(url) {
            expand(url) { [weak self] expanded in
                guard let self = self else { return }
                guard let expanded = expanded else { return self.fail("Couldn't load that link — is the network on?") }
                self.parseAndFinish(url: expanded, text: text)
            }
        } else {
            parseAndFinish(url: url, text: text)
        }
    }

    /// Follow redirects to the full maps URL. GET, not HEAD — Google's
    /// short-link service doesn't always redirect HEAD requests.
    private func expand(_ url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { _, response, _ in
            DispatchQueue.main.async { completion(response?.url) }
        }
        task.resume()
    }

    private func parseAndFinish(url: URL, text: String?) {
        guard let place = PlaceURLParser.parse(url, sharedText: text) else { return fail() }
        let name = place.name ?? ""

        if place.coordinatesValid && !name.isEmpty {
            finish(name: name, address: place.address ?? "", lat: place.lat!, lng: place.lng!)
        } else if !name.isEmpty {
            // Name but no usable coordinates → forward-geocode the name.
            geocoder.geocodeAddressString(name) { [weak self] marks, _ in
                guard let self = self else { return }
                guard let loc = marks?.first?.location,
                      ParsedPlace.valid(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
                else { return self.fail() }
                self.finish(name: name, address: place.address ?? "",
                            lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
            }
        } else if place.coordinatesValid {
            // Coordinates but no name → reverse-geocode for a label.
            let loc = CLLocation(latitude: place.lat!, longitude: place.lng!)
            geocoder.reverseGeocodeLocation(loc) { [weak self] marks, _ in
                guard let self = self else { return }
                let label = marks?.first?.name ?? "Shared place"
                self.finish(name: label, address: place.address ?? "",
                            lat: place.lat!, lng: place.lng!)
            }
        } else {
            fail()
        }
    }

    // MARK: - Outcomes

    private func finish(name: String, address: String, lat: Double, lng: Double) {
        guard let suite = UserDefaults(suiteName: appGroupID) else {
            return fail("App Group unavailable — check signing.")
        }
        var queue = suite.array(forKey: pendingImportsKey) as? [[String: Any]] ?? []
        queue.append([
            "searchedText": name,
            "address": address,
            "lat": NSNumber(value: lat),
            "lng": NSNumber(value: lng)
        ])
        suite.set(queue, forKey: pendingImportsKey)

        spinner.stopAnimating()
        statusLabel.text = "Added \(name) ✓"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    private func fail(_ message: String = "Couldn't read a location from this share.") {
        spinner.stopAnimating()
        statusLabel.text = message
        cancelButton.isHidden = false
    }
}
```

- [ ] **Step 4: Install the xcodeproj gem (not currently installed)**

Run: `gem install xcodeproj --user-install 2>&1 | tail -2`
Expected: `1 gem installed` (or already-installed notice). If the user-gem bin dir isn't on PATH that's fine — the script is invoked with `ruby`, which finds user-installed gems automatically. If installation fails from the sandbox, rerun with permissions.

- [ ] **Step 5: Write the target-creation script**

`scripts/add_share_extension.rb`:

```ruby
#!/usr/bin/env ruby
# Adds the "Crowsflight Share" share-extension target to Crowsflight.xcodeproj.
# Idempotent: exits if the target already exists.
require 'xcodeproj'

project_path = File.expand_path('../Crowsflight.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

if project.targets.any? { |t| t.name == 'Crowsflight Share' }
  puts 'Crowsflight Share target already exists — nothing to do.'
  exit 0
end

app_target = project.targets.find { |t| t.name == 'Crowsflight' }
raise 'Crowsflight app target not found' unless app_target

ext_target = project.new_target(:app_extension, 'Crowsflight Share', :ios, '14.0')

ext_target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.cwandt.crowsflight.share'
  s['SWIFT_VERSION']             = '5.0'
  s['DEVELOPMENT_TEAM']          = 'L6DVQR8JB9'
  s['CODE_SIGN_STYLE']           = 'Automatic'
  s['CODE_SIGN_ENTITLEMENTS']    = 'CrowsflightShare/CrowsflightShare.entitlements'
  s['INFOPLIST_FILE']            = 'CrowsflightShare/Info.plist'
  s['GENERATE_INFOPLIST_FILE']   = 'NO'
  s['MARKETING_VERSION']         = '1.0'
  s['CURRENT_PROJECT_VERSION']   = '1'
  s['TARGETED_DEVICE_FAMILY']    = '1,2'
  s['SKIP_INSTALL']              = 'YES'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
end

# Source files: the view controller + the parser (compiled directly into the
# extension, so no framework/package linkage is needed).
group = project.main_group.new_group('CrowsflightShare', 'CrowsflightShare')
vc_ref = group.new_file('ShareViewController.swift')
group.new_file('Info.plist')
group.new_file('CrowsflightShare.entitlements')

parser_group = project.main_group.new_group('SharedPlacesSources', 'SharedPlaces/Sources/SharedPlaces')
parser_ref = parser_group.new_file('PlaceURLParser.swift')

ext_target.add_file_references([vc_ref, parser_ref])

# Embed the extension in the app.
app_target.add_dependency(ext_target)
embed = app_target.new_copy_files_build_phase('Embed App Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
bf = embed.add_file_reference(ext_target.product_reference)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

project.save
puts 'Added Crowsflight Share target and embedded it in Crowsflight.'
```

- [ ] **Step 6: Run the script**

Run: `cd "$(git rev-parse --show-toplevel)" && ruby scripts/add_share_extension.rb`
Expected: `Added Crowsflight Share target and embedded it in Crowsflight.`

- [ ] **Step 7: Build to verify**

Run:
```bash
xcodebuild -project Crowsflight.xcodeproj -scheme Crowsflight \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`. The Crowsflight scheme builds the extension via the new target dependency. If the build fails on unrelated legacy warnings-as-errors, report the exact error — do not disable warnings project-wide.

- [ ] **Step 8: Commit**

```bash
git add CrowsflightShare scripts/add_share_extension.rb Crowsflight.xcodeproj/project.pbxproj
git commit -m "feat: add Crowsflight Share extension target"
```

---

### Task 3: Main-app ingestion (`drainPendingImports`)

**Files:**
- Modify: `Crowsflight/cwtAppDelegate.h` (add one method declaration after line 50)
- Modify: `Crowsflight/cwtAppDelegate.m` (new methods + one call in `applicationDidBecomeActive:` at line 553)

**Interfaces:**
- Consumes: App Group inbox format from Task 2; existing `addNewDestination:newlat:newlng:` (`cwtAppDelegate.m:392`) which appends, persists, sets `currentDestinationN`, and syncs iCloud + Watch; existing `[self.viewController flipToPage:]` pattern from the URL-scheme handler (`cwtAppDelegate.m:198`).
- Produces: `-(void)drainPendingImports;` on `cwtAppDelegate`.

**Design notes for the implementer:**
- Call `drainPendingImports` ONLY from `applicationDidBecomeActive:` — it fires both after launch and on every foreground, so one call site covers both without double-processing.
- Clear the inbox BEFORE processing (crash mid-import loses the import rather than double-adding — the safer failure).
- Dedupe at 4 decimal places (~11 m): a re-shared place selects the existing entry instead of duplicating.

- [ ] **Step 1: Declare the method in the header**

In `Crowsflight/cwtAppDelegate.h`, after line 50 (`-(void)iCloudSync;`), add:

```objc
-(void)drainPendingImports;
```

- [ ] **Step 2: Implement in cwtAppDelegate.m**

Add immediately after the `iCloudSync` method (after line 442):

```objc
#pragma mark - Share extension inbox

static NSString * const kAppGroupID = @"group.com.cwandt.crowsflight";
static NSString * const kPendingImportsKey = @"pendingImports";

-(NSInteger)indexOfDestinationMatchingLat:(double)lat lng:(double)lng{
    for (NSUInteger i = 0; i < [self.locationDictionaryArray count]; i++) {
        NSDictionary *d = [self.locationDictionaryArray objectAtIndex:i];
        double dlat = [[d objectForKey:@"lat"] doubleValue];
        double dlng = [[d objectForKey:@"lng"] doubleValue];
        if (llround(dlat * 10000.0) == llround(lat * 10000.0) &&
            llround(dlng * 10000.0) == llround(lng * 10000.0)) {
            return (NSInteger)i;
        }
    }
    return -1;
}

-(void)drainPendingImports{
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupID];
    NSArray *pending = [shared arrayForKey:kPendingImportsKey];
    if ([pending count] == 0) return;
    [shared removeObjectForKey:kPendingImportsKey];

    for (NSDictionary *item in pending) {
        NSString *name = [item objectForKey:@"searchedText"];
        double lat = [[item objectForKey:@"lat"] doubleValue];
        double lng = [[item objectForKey:@"lng"] doubleValue];

        if (![name isKindOfClass:[NSString class]] || [name length] == 0) continue;
        if (lat == 0.0 && lng == 0.0) continue;
        if (fabs(lat) > 90.0 || fabs(lng) > 180.0) continue;

        NSInteger existing = [self indexOfDestinationMatchingLat:lat lng:lng];
        if (existing >= 0) {
            [[NSUserDefaults standardUserDefaults] setInteger:existing forKey:@"currentDestinationN"];
            NSLog(@"Import: duplicate of %ld, selecting it", (long)existing);
        } else {
            [self addNewDestination:name newlat:lat newlng:lng];
            NSLog(@"Import: added %@", name);
        }
    }

    if (self.viewController) {
        [self.viewController flipToPage:[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDestinationN"]];
    }
}
```

- [ ] **Step 3: Call it on foreground**

In `applicationDidBecomeActive:` (`cwtAppDelegate.m:553`), add as the FIRST line of the method body:

```objc
    [self drainPendingImports];
```

- [ ] **Step 4: Build to verify**

Run:
```bash
xcodebuild -project Crowsflight.xcodeproj -scheme Crowsflight \
  -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add Crowsflight/cwtAppDelegate.h Crowsflight/cwtAppDelegate.m
git commit -m "feat: ingest share-extension pending imports on foreground"
```

---

### Task 4: End-to-end verification on the simulator

**Files:** none created — verification only. Consult the project memory note "Crowsflight test setup" for simulator driving (simtouch), the device ID, and the two-window gotcha.

**Interfaces:**
- Consumes: everything from Tasks 1–3.
- Produces: verified feature; report with evidence.

- [ ] **Step 1: Build and install on a booted simulator**

```bash
xcrun simctl boot "iPhone 16" 2>/dev/null; open -a Simulator
xcodebuild -project Crowsflight.xcodeproj -scheme Crowsflight \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -3
APP=$(find ~/Library/Developer/Xcode/DerivedData -path '*Debug-iphonesimulator/Crowsflight.app' | head -1)
xcrun simctl install booted "$APP"
```
Expected: BUILD SUCCEEDED; install completes silently. (Use whatever iPhone simulator is available if "iPhone 16" isn't — `xcrun simctl list devices available`.)

- [ ] **Step 2: Record the pre-import state**

```bash
CONT=$(xcrun simctl get_app_container booted com.cwandt.crowsflight data)
plutil -p "$CONT/Documents/locationList.plist" | tail -5
```
Expected: prints current saved places (launch the app once first if the file doesn't exist yet). Note the count.

- [ ] **Step 3: Share a Google Maps URL from Safari**

Google Maps app isn't on the simulator, so exercise the extension through Safari's share sheet with a full place URL:

```bash
xcrun simctl openurl booted "https://www.google.com/maps/place/Fort+Greene+Park/@40.6905615,-73.9762079,17z/data=!8m2!3d40.6913984!4d-73.9755405"
```

Then in the Simulator UI (simtouch or manually): tap Safari's share button → find **Crowsflight** in the share sheet (enable it under "Edit Actions…" on first use) → tap it. Expected: the card shows "Added Fort Greene Park ✓" and dismisses.

- [ ] **Step 4: Verify ingestion**

Launch Crowsflight (`xcrun simctl launch booted com.cwandt.crowsflight`), then:

```bash
plutil -p "$CONT/Documents/locationList.plist" | tail -8
xcrun simctl spawn booted defaults read com.cwandt.crowsflight currentDestinationN
```
Expected: `FORT GREENE PARK`-titled entry appended with lat ≈ 40.6913984, lng ≈ -73.9755405; `currentDestinationN` equals the new last index; the app UI shows the compass pointing at it.

- [ ] **Step 5: Verify dedupe**

Repeat Step 3 with the same URL, relaunch the app. Expected: place count unchanged (no duplicate), `currentDestinationN` still points at the Fort Greene Park entry.

- [ ] **Step 6: Verify an Apple Maps URL**

```bash
xcrun simctl openurl booted "https://maps.apple.com/?ll=40.7061,-73.9969&q=Brooklyn%20Bridge%20Park"
```
Share from Safari → Crowsflight as before. Note: the seed plist already contains "Brooklyn Bridge" at (40.70553, -73.99626) — this is a DIFFERENT point ~120 m away, so it must be ADDED, not deduped. Expected: new entry "Brooklyn Bridge Park".

- [ ] **Step 7: Commit any fixes found, report results**

If verification exposed bugs, fix them, re-run the failing step, and commit with a `fix:` message. Report: what was shared, what landed in the plist, dedupe behavior, and any deviations.

---

## Deferred (noted, not planned)

- **Device run / App Store submission**: on a physical device the App Group must be present in both provisioning profiles. With automatic signing, building once in Xcode with the team logged in (or `xcodebuild -allowProvisioningUpdates`) registers `com.cwandt.crowsflight.share` and attaches the existing group. Do this when the user next runs on device.
- **Watch verification**: the existing `transferLocations` fires from `iCloudSync` inside `addNewDestination:`, so imported places reach the Watch with no new code; verify opportunistically when a paired Watch sim is running.

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
            || host == "maps.apple"
    }

    public static func parse(_ url: URL, sharedText: String?) -> ParsedPlace? {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = comps.host?.lowercased() else { return nil }

        var place: ParsedPlace
        let isGoogleHost = host == "google.com"
            || host.hasSuffix(".google.com")
            || matches(of: "^(www\\.|maps\\.)?google\\.[a-z]{2,3}(\\.[a-z]{2})?$", in: host).first != nil
        if isGoogleHost {
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

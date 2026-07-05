import UIKit
import CoreLocation
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private let appGroupID = "group.com.cwandt.crowsflight"
    private let pendingImportsKey = "pendingImports"
    private let diagnosticsKey = "shareDiagnostics"
    private lazy var appGroupSuite = UserDefaults(suiteName: appGroupID)

    private let card = UIView()
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let cancelButton = UIButton(type: .system)
    private let geocoder = CLGeocoder()
    /// URLSession.shared is documented as unavailable in app extensions — own a session.
    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

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
        cancelButton.isHidden = false
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

    // MARK: - Diagnostics (share runs are invisible from the debugger — leave a trail
    // in the app group that `devicectl device copy from` can pull off the phone)

    private func diag(_ s: String) {
        guard let suite = appGroupSuite else { return }
        var lines = suite.stringArray(forKey: diagnosticsKey) ?? []
        lines.append(String(s.prefix(300)))
        suite.set(Array(lines.suffix(60)), forKey: diagnosticsKey)
    }

    private func diagItem(_ kind: String, _ item: Any?, _ err: Error?) {
        diag("\(kind) item: \(type(of: item)) err: \(String(describing: err)) value: \(String(describing: item))")
    }

    // MARK: - Resolution pipeline

    private func resolveSharedItem() {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .flatMap { $0.attachments ?? [] } ?? []
        diag("--- share \(Date()) providers: \(providers.map { $0.registeredTypeIdentifiers })")

        if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            p.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, err in
                self?.diagItem("url", item, err)
                DispatchQueue.main.async { self?.handle(url: item as? URL, text: nil) }
            }
        } else if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            p.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, err in
                let text = item as? String
                self?.diagItem("text", item, err)
                DispatchQueue.main.async {
                    self?.handle(url: text.flatMap { PlaceURLParser.extractURL(from: $0) }, text: text)
                }
            }
        } else {
            diag("no url/text provider")
            fail()
        }
    }

    private func handle(url: URL?, text: String?) {
        guard let url = url else { diag("handle: no url"); return fail() }
        let isShortLink = PlaceURLParser.isShortLink(url)
        diag("handle shortLink: \(isShortLink) url: \(url.absoluteString)")
        if isShortLink {
            expand(url) { [weak self] expanded in
                guard let self = self else { return }
                self.diag("expanded: \(expanded?.absoluteString ?? "nil")")
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
        let task = urlSession.dataTask(with: url) { _, response, _ in
            DispatchQueue.main.async { completion(response?.url) }
        }
        task.resume()
    }

    private func parseAndFinish(url: URL, text: String?) {
        let parsed = PlaceURLParser.parse(url, sharedText: text)
        diag("parsed: \(String(describing: parsed))")
        guard let place = parsed else { return fail() }
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
        cancelButton.isHidden = true
        diag("finish: queued \(name)")
        guard let suite = appGroupSuite else {
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
        diag("fail: \(message)")
        spinner.stopAnimating()
        statusLabel.text = message
        cancelButton.isHidden = false
    }
}

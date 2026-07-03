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

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Location",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Location", targets: ["Location"]),
    ],
    targets: [
        .target(name: "Location"),
        .testTarget(name: "LocationTests", dependencies: ["Location"])
    ]
)

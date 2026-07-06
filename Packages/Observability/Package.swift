// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Observability",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Observability", targets: ["Observability"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
    ],
    targets: [
        .target(name: "Observability", dependencies: ["Core", "Domain"]),
        .testTarget(name: "ObservabilityTests", dependencies: ["Observability"]),
    ]
)

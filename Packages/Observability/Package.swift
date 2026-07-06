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
        .package(path: "../DesignSystem"),
    ],
    targets: [
        .target(name: "Observability", dependencies: ["Core", "Domain", "DesignSystem"]),
        .testTarget(name: "ObservabilityTests", dependencies: ["Observability", "Domain"]),
    ]
)

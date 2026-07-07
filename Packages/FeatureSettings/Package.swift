// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureSettings",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "FeatureSettings", targets: ["FeatureSettings"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../DIContainer"),
        .package(path: "../Domain"),
        .package(path: "../Data"),
        .package(path: "../Observability"),
    ],
    targets: [
        .target(name: "FeatureSettings", dependencies: ["Core", "DesignSystem", "DIContainer", "Domain", "Data", "Observability"]),
        .testTarget(name: "FeatureSettingsTests", dependencies: ["FeatureSettings"]),
    ]
)

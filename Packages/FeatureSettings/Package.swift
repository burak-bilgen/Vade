// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureSettings",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "FeatureSettings", targets: ["FeatureSettings"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../DIContainer"),
        .package(path: "../Domain"),
    ],
    targets: [
        .target(name: "FeatureSettings", dependencies: ["Core", "DesignSystem", "DIContainer", "Domain"]),
        .testTarget(name: "FeatureSettingsTests", dependencies: ["FeatureSettings"]),
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureWidget",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "FeatureWidget", targets: ["FeatureWidget"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../Domain"),
        .package(path: "../Observability"),
    ],
    targets: [
        .target(name: "FeatureWidget", dependencies: ["Core", "DesignSystem", "Domain", "Observability"]),
        .testTarget(name: "FeatureWidgetTests", dependencies: ["FeatureWidget"]),
    ]
)

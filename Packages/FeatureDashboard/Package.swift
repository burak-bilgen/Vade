// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureDashboard",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "FeatureDashboard", targets: ["FeatureDashboard"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../Domain"),
        .package(path: "../Data"),
        .package(path: "../Networking"),
        .package(path: "../Observability"),
    ],
    targets: [
        .target(name: "FeatureDashboard", dependencies: ["Core", "DesignSystem", "Domain", "Networking", "Observability"]),
        .testTarget(name: "FeatureDashboardTests", dependencies: ["FeatureDashboard", "Data"]),
    ]
)

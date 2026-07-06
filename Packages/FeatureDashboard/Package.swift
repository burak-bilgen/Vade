// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureDashboard",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "FeatureDashboard", targets: ["FeatureDashboard"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../DIContainer"),
        .package(path: "../Domain"),
        .package(path: "../Data"),
        .package(path: "../Networking"),
        .package(path: "../FeatureDebtDetail"),
        .package(path: "../Observability"),
    ],
    targets: [
        .target(name: "FeatureDashboard", dependencies: ["Core", "DesignSystem", "DIContainer", "Domain", "Data", "Networking", "FeatureDebtDetail", "Observability"]),
        .testTarget(name: "FeatureDashboardTests", dependencies: ["FeatureDashboard", "Data"]),
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureDebtDetail",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "FeatureDebtDetail", targets: ["FeatureDebtDetail"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../DIContainer"),
        .package(path: "../Domain"),
        .package(path: "../Data"),
    ],
    targets: [
        .target(name: "FeatureDebtDetail", dependencies: ["Core", "DesignSystem", "DIContainer", "Domain", "Data"]),
        .testTarget(name: "FeatureDebtDetailTests", dependencies: ["FeatureDebtDetail", "Data"]),
    ]
)

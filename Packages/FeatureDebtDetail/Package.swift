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
    ],
    targets: [
        .target(name: "FeatureDebtDetail", dependencies: ["Core", "DesignSystem", "DIContainer", "Domain"]),
        .testTarget(name: "FeatureDebtDetailTests", dependencies: ["FeatureDebtDetail"]),
    ]
)

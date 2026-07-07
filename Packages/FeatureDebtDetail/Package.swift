// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureDebtDetail",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "FeatureDebtDetail", targets: ["FeatureDebtDetail"]),
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
        .target(name: "FeatureDebtDetail", dependencies: ["Core", "DesignSystem", "DIContainer", "Domain", "Data", "Observability"]),
        .testTarget(name: "FeatureDebtDetailTests", dependencies: ["FeatureDebtDetail", "Data"]),
    ]
)

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
        .package(path: "../Domain"),
        .package(path: "../Data"),
        .package(path: "../Observability"),
        .package(path: "../Networking"),
    ],
    targets: [
        .target(name: "FeatureDebtDetail", dependencies: ["Core", "DesignSystem", "Domain", "Observability", "Networking"]),
        .testTarget(name: "FeatureDebtDetailTests", dependencies: ["FeatureDebtDetail", "Data"]),
    ]
)

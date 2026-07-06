// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Vade",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "VadeApp", targets: ["VadeApp"]),
    ],
    dependencies: [
        .package(path: "Packages/Core"),
        .package(path: "Packages/DesignSystem"),
        .package(path: "Packages/DIContainer"),
        .package(path: "Packages/Observability"),
        .package(path: "Packages/Domain"),
        .package(path: "Packages/Data"),
        .package(path: "Packages/Networking"),
        .package(path: "Packages/FeatureOnboarding"),
        .package(path: "Packages/FeatureDashboard"),
        .package(path: "Packages/FeatureDebtDetail"),
        .package(path: "Packages/FeatureSettings"),
        .package(path: "Packages/FeatureWidget"),
    ],
    targets: [
        .target(
            name: "VadeApp",
            path: "App/Sources/Vade",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)

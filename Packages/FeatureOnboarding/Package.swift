// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeatureOnboarding",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "FeatureOnboarding", targets: ["FeatureOnboarding"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../DesignSystem"),
        .package(path: "../DIContainer"),
        .package(path: "../Domain"),
    ],
    targets: [
        .target(
            name: "FeatureOnboarding",
            dependencies: ["Core", "DesignSystem", "DIContainer", "Domain"],
            path: "Sources/FeatureOnboarding"
        ),
        .testTarget(
            name: "FeatureOnboardingTests",
            dependencies: ["FeatureOnboarding"],
            path: "Tests/FeatureOnboardingTests"
        ),
    ]
)

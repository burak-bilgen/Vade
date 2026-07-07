// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: ["Core", "Domain"],
            path: "Sources/DesignSystem",
            resources: []
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        ),
    ]
)

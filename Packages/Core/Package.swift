// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Core", targets: ["Core"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Core", dependencies: []),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)

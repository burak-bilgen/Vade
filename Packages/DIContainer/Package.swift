// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DIContainer",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "DIContainer", targets: ["DIContainer"]),
    ],
    targets: [
        .target(name: "DIContainer"),
        .testTarget(name: "DIContainerTests", dependencies: ["DIContainer"]),
    ]
)

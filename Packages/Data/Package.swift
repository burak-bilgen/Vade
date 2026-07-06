// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Data",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Data", targets: ["Data"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
    ],
    targets: [
        .target(name: "Data", dependencies: ["Core", "Domain"]),
        .testTarget(name: "DataTests", dependencies: ["Data"]),
    ]
)

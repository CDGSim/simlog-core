// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SimlogCore",
    products: [
        .library(
            name: "simlog-core",
            targets: ["simlog-core"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "simlog-core",
            dependencies: []),
        .testTarget(
            name: "simlog-coreTests",
            dependencies: ["simlog-core"]),
    ]
)

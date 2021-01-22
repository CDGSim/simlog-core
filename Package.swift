// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "simlog-core",
    products: [
        .library(name: "SimlogCore",
                 targets: ["SimlogCore"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SimlogCore",
            dependencies: []),
        .testTarget(
            name: "SimlogCoreTests",
            dependencies: ["SimlogCore"]),
    ]
)

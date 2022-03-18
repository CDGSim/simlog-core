// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "simlog-core",
    products: [
        .library(name: "SimlogCore",
                 targets: ["SimlogCore"]),
    ],
    dependencies: [
                   .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.13.1")
    ],
    targets: [
        .target(
            name: "SimlogCore",
            dependencies: [
                .product(name: "XMLCoder", package: "XMLCoder")
            ],
            resources: [.process("Resources")]),
        .testTarget(
            name: "SimlogCoreTests",
            dependencies: ["SimlogCore"],
            resources: [.process("Resources")]),
    ]
)

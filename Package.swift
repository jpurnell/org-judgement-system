// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "org-judgement-system",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "IJSCore",
            targets: ["IJSCore"]
        ),
    ],
    dependencies: [
        .package(path: "../quality-gate-types"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "IJSCore",
            dependencies: [
                .product(name: "QualityGateTypes", package: "quality-gate-types"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/IJSCore"
        ),
        .testTarget(
            name: "IJSCoreTests",
            dependencies: ["IJSCore"],
            path: "Tests/IJSCoreTests"
        ),
    ]
)

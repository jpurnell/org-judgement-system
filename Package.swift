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
    ],
    targets: [
        .target(
            name: "IJSCore",
            dependencies: [
                .product(name: "QualityGateTypes", package: "quality-gate-types"),
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

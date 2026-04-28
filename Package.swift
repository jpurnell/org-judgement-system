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
    targets: [
        .target(
            name: "IJSCore",
            path: "Sources/IJSCore"
        ),
        .testTarget(
            name: "IJSCoreTests",
            dependencies: ["IJSCore"],
            path: "Tests/IJSCoreTests"
        ),
    ]
)

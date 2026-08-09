// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Clicore",
    products: [
        .library(
            name: "Clicore",
            targets: ["Clicore"],
        ),
    ],
    targets: [
        .target(
            name: "Clicore",
            path: "Sources",
        ),
        .testTarget(
            name: "ClicoreTests",
            dependencies: ["Clicore"]
        ),
    ]
)

// swift-tools-version: 5.4

import PackageDescription

let package = Package(
    name: "Clicore",
    products: [
        .library(name: "Clicore", targets: ["caper"]),
    targets: [
        .target(
            name: "clicore",
            path: ".",
        )
    ]
)

// swift-tools-version: 5.4

import PackageDescription

let package = Package(
    name: "ClicorePackage",
    products: [
        .library(name: "Clicore", targets: ["ClicoreTarget"]),
    targets: [
        .target(
            name: "ClicoreTarget",
            path: ".",
        )
    ]
)

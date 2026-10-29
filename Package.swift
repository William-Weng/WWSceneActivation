// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWSceneActivation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "WWSceneActivation", targets: ["WWSceneActivation"]),
    ],
    targets: [
        .target(name: "WWSceneActivation", resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)

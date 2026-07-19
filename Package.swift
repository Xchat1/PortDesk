// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PortDeck",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "PortDeck"
        ),
        .testTarget(
            name: "PortDeckTests",
            dependencies: ["PortDeck"]
        ),
    ]
)

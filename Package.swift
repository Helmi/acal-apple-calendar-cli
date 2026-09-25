// swift-tools-version: 6.2

import Foundation
import PackageDescription

/// Embedding Info.plist gives the executable its own identity (com.helmi.acal) so macOS TCC
/// attributes Calendar access to acal instead of whichever process launched it.
let infoPlistPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Support/Info.plist")
    .path

let package = Package(
    name: "acal",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "acal", targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                "AppCore",
                "EventKitAdapter",
                "Formatting",
                "Diagnostics",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MCP", package: "swift-sdk")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", infoPlistPath
                ])
            ]
        ),
        .target(name: "AppCore"),
        .target(
            name: "EventKitAdapter",
            dependencies: ["AppCore"]
        ),
        .target(
            name: "Formatting",
            dependencies: ["AppCore"]
        ),
        .target(
            name: "Diagnostics",
            dependencies: [
                "AppCore",
                "EventKitAdapter"
            ]
        ),
        .testTarget(
            name: "ACalTests",
            dependencies: [
                "AppCore",
                "App",
                "Formatting",
                "EventKitAdapter",
                "Diagnostics"
            ]
        )
    ]
)

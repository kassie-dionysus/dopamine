// swift-tools-version: 6.0
import PackageDescription

// Swift-only package layout for Dopamine (core engine, SwiftUI module, CLI harness, and tests).
let package = Package(
    name: "Dopamine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "DopamineCore", targets: ["DopamineCore"]),
        .library(name: "DopamineUI", targets: ["DopamineUI"]),
        .executable(name: "DopamineCLI", targets: ["DopamineCLI"])
    ],
    targets: [
        .target(name: "DopamineCore"),
        .target(
            name: "DopamineUI",
            dependencies: ["DopamineCore"]
        ),
        .executableTarget(
            name: "DopamineCLI",
            dependencies: ["DopamineCore"]
        ),
        .testTarget(
            name: "DopamineCoreTests",
            dependencies: ["DopamineCore"]
        )
    ]
)

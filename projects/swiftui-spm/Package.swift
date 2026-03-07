// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MathLibDemo",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "MathLib",
            path: "Sources/MathLib",
            publicHeadersPath: "include"
        ),
        .target(
            name: "MathBridge",
            dependencies: ["MathLib"],
            path: "Sources/MathBridge"
        ),
        .executableTarget(
            name: "MacApp",
            dependencies: ["MathBridge"],
            path: "Sources/MacApp"
        ),
        .testTarget(
            name: "MathBridgeTests",
            dependencies: ["MathBridge"],
            path: "Tests/MathBridgeTests"
        ),
    ]
)

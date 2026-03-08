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
        .target(
            name: "TaskRunner",
            path: "Sources/TaskRunner"
        ),
        .executableTarget(
            name: "MacApp",
            dependencies: ["MathBridge", "TaskRunner"],
            path: "Sources/MacApp",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "MathBridgeTests",
            dependencies: ["MathBridge"],
            path: "Tests/MathBridgeTests"
        ),
        .testTarget(
            name: "TaskRunnerTests",
            dependencies: ["TaskRunner"],
            path: "Tests/TaskRunnerTests"
        ),
    ]
)

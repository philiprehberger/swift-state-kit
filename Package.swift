// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-state-kit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "StateKit", targets: ["StateKit"])
    ],
    targets: [
        .target(
            name: "StateKit",
            path: "Sources/StateKit"
        ),
        .testTarget(
            name: "StateKitTests",
            dependencies: ["StateKit"],
            path: "Tests/StateKitTests"
        )
    ]
)

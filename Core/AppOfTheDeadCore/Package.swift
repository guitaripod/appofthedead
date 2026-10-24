// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppOfTheDeadCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "AppOfTheDeadCore", targets: ["AppOfTheDeadCore"]),
    ],
    targets: [
        .target(
            name: "AppOfTheDeadCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
            ]
        ),
        .testTarget(
            name: "AppOfTheDeadCoreTests",
            dependencies: ["AppOfTheDeadCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
            ]
        ),
    ]
)

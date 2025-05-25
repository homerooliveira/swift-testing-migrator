// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-testing-migrator",
    platforms: [
        .macOS(.v15),
    ], dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
    ],
    targets: [
        .executableTarget(
            name: "swift-testing-migrator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "TestingMigrator",
            ],
            swiftSettings: .defaultSwiftSettings,
        ),
        .target(
            name: "TestingMigrator",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            swiftSettings: .defaultSwiftSettings,
        ),
        .testTarget(
            name: "TestingMigratorTests",
            dependencies: [
                "TestingMigrator",
            ],
            resources: [
                .copy("Resources/"),
            ],
            swiftSettings: .defaultSwiftSettings,
        ),
    ],
)

extension [SwiftSetting] {
    static var defaultSwiftSettings: [SwiftSetting] {
        [
            .unsafeFlags(["-warnings-as-errors"]),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
        ]
    }
}

// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SteamcLog",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "SteamcLog",
            targets: ["SteamcLog"]),
    ],
    dependencies: [
        .package(url: "https://github.com/DaveWoodCom/XCGLogger", from: "7.0.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "9.0.0"),
    ],
    targets: [
        .target(
            name: "SteamcLog",
            dependencies: ["XCGLogger", .product(name: "Sentry", package: "sentry-cocoa")],
            path: "SteamcLog"),
    ],
    swiftLanguageVersions: [.v5]
)

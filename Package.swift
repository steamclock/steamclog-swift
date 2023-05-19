// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SteamcLog",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "SteamcLog",
            targets: ["SteamcLog"]),
    ],
    dependencies: [
        .package(url: "https://github.com/DaveWoodCom/XCGLogger", from: "7.0.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0"),
    ],
    targets: [
        .target(
            name: "SteamcLog",
            dependencies: ["XCGLogger", "Sentry"],
            path: "SteamcLog"),
    ],
    swiftLanguageVersions: [.v5]
)

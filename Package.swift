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
        .library(
            name: "SteamcLogNetable",
            targets: ["SteamcLogNetable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "9.0.0"),
        .package(url: "https://github.com/steamclock/netable", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "SteamcLog",
            dependencies: [.product(name: "Sentry", package: "sentry-cocoa")],
            path: "SteamcLog"),
        .target(
            name: "SteamcLogNetable",
            dependencies: ["SteamcLog", .product(name: "Netable", package: "netable")],
            path: "Netable"),
        .testTarget(
            name: "SteamcLogTests",
            dependencies: ["SteamcLog"],
            path: "Tests"),
    ],
    swiftLanguageVersions: [.v5]
)

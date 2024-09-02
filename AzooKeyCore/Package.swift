// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("ImplicitOpenExistentials"),
    .enableUpcomingFeature("StrictConcurrency"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("ImportObjcForwardDeclarations"),
    .unsafeFlags(["-strict-concurrency=complete"])
]
let package = Package(
    name: "AzooKeyCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftUIUtils",
            targets: ["SwiftUIUtils"]
        ),
        .library(
            name: "KeyboardThemes",
            targets: ["KeyboardThemes"]
        ),
        .library(
            name: "KeyboardViews",
            targets: ["KeyboardViews"]
        ),
        .library(
            name: "AzooKeyUtils",
            targets: ["AzooKeyUtils"]
        ),
        .library(
            name: "KeyboardExtensionUtils",
            targets: ["KeyboardExtensionUtils"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // MARK: You must specify version which results reproductive and stable result
        // MARK: `_: .upToNextMinor(Version)` or `exact: Version` or `revision: Version`.
        // MARK: For develop branch, you can use `revision:` specification.
        // MARK: For main branch, you must use `upToNextMinor` specification.
        .package(url: "https://github.com/ensan-hcl/AzooKeyKanaKanjiConverter", .upToNextMinor(from: "0.7.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftUIUtils",
            dependencies: [
                .product(name: "SwiftUtils", package: "AzooKeyKanaKanjiConverter")
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "KeyboardThemes",
            dependencies: [
                .product(name: "SwiftUtils", package: "AzooKeyKanaKanjiConverter")
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "KeyboardViews",
            dependencies: [
                "KeyboardThemes",
                "KeyboardExtensionUtils",
                .product(name: "KanaKanjiConverterModule", package: "AzooKeyKanaKanjiConverter")
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "AzooKeyUtils",
            dependencies: [
                "KeyboardThemes",
                "KeyboardViews"
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "KeyboardExtensionUtils",
            dependencies: [
                .product(name: "KanaKanjiConverterModule", package: "AzooKeyKanaKanjiConverter")
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "KeyboardExtensionUtilsTests",
            dependencies: [
                "KeyboardExtensionUtils"
            ]
        )
    ]
)

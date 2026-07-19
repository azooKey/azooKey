// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .interoperabilityMode(.Cxx),
]

let package = Package(
    name: "AzooKeyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
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
        ),
        .library(
            name: "CustardKit",
            targets: ["CustardKit"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // MARK: You must specify version which results reproductive and stable result
        // MARK: `_: .upToNextMinor(Version)` or `exact: Version` or `revision: Version`.
        // MARK: For develop branch, you can use `revision:` specification.
        // MARK: For main branch, you must use `upToNextMinor` specification.
        .package(url: "https://github.com/azooKey/AzooKeyKanaKanjiConverter", revision: "1def030b6697fb3811f2ae642719811db6b70c3e", traits: ["ZenzaiCPU"]),
    ],
    targets: [
        .target(
            name: "CustardKit",
            dependencies: [],
            swiftSettings: swiftSettings
        ),
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
                "SwiftUIUtils",
                .product(name: "SwiftUtils", package: "AzooKeyKanaKanjiConverter"),
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "KeyboardViews",
            dependencies: [
                "SwiftUIUtils",
                "KeyboardThemes",
                "KeyboardExtensionUtils",
                "CustardKit",
                .product(name: "KanaKanjiConverterModule", package: "AzooKeyKanaKanjiConverter"),
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "AzooKeyUtils",
            dependencies: [
                "CustardKit",
                "KeyboardThemes",
                "KeyboardViews",
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "KeyboardExtensionUtils",
            dependencies: [
                "CustardKit",
                .product(name: "KanaKanjiConverterModule", package: "AzooKeyKanaKanjiConverter"),
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CustardKitTests",
            dependencies: [
                "CustardKit",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "KeyboardExtensionUtilsTests",
            dependencies: [
                "KeyboardExtensionUtils",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AzooKeyUtilsTests",
            dependencies: [
                "AzooKeyUtils",
                "CustardKit",
                "KeyboardViews",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "KeyboardViewsTests",
            dependencies: [
                "KeyboardViews",
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

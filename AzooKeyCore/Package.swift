// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .interoperabilityMode(.Cxx),
]

#if canImport(FoundationModels)
let isXcodeVersion26 = true
#else
let isXcodeVersion26 = false
#endif

let xcode26AdditionalTargets: [Target] = [
    .binaryTarget(
        // Note: Xcode 26以降、AzooKeyKanaKanjiConverter側のXCFrameworkのbinaryTargetをXcodeが解決してくれなくなった。
        // そこで、binaryTargetを再度AzooKeyCore側でも要求することで、結果的に認識されるようになる。
        // さらに`AzooKeyUtils`でも`llama`を要求しないとビルドは通らない。
        // ただし、Xcode 26より前の場合は逆にこの対応を入れると動作しないので、Xcodeバージョンを確認する必要がある
        name: "llama",
        url: "https://github.com/azooKey/llama.cpp/releases/download/b4846/signed-llama.xcframework.zip",
        // this can be computed `swift package compute-checksum llama-b4844-xcframework.zip`
        checksum: "db3b13169df8870375f212e6ac21194225f1c85f7911d595ab64c8c790068e0a"
    ),
]

let xcode26AdditionalTargetDependency: [Target.Dependency] = [
    "llama"
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
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // MARK: You must specify version which results reproductive and stable result
        // MARK: `_: .upToNextMinor(Version)` or `exact: Version` or `revision: Version`.
        // MARK: For develop branch, you can use `revision:` specification.
        // MARK: For main branch, you must use `upToNextMinor` specification.
        .package(url: "https://github.com/azooKey/AzooKeyKanaKanjiConverter", revision: "2646d6d5c9dbcd3c898610bf2d394181d18a806f", traits: ["ZenzaiCPU"]),
        .package(url: "https://github.com/azooKey/CustardKit", revision: "563635caf1213dd6b2baff63ed1b0cf254b9d78a"),
    ],
    targets: [
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
                .product(name: "KanaKanjiConverterModule", package: "AzooKeyKanaKanjiConverter"),
                .product(name: "CustardKit", package: "CustardKit"),
            ],
            resources: [],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "AzooKeyUtils",
            dependencies: [
                "KeyboardThemes",
                "KeyboardViews",
            ] + (isXcodeVersion26 ? xcode26AdditionalTargetDependency : []),
            resources: [],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "KeyboardExtensionUtils",
            dependencies: [
                .product(name: "CustardKit", package: "CustardKit"),
                .product(name: "KanaKanjiConverterModule", package: "AzooKeyKanaKanjiConverter"),
            ],
            resources: [],
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
            ],
            swiftSettings: swiftSettings
        ),
    ] + (isXcodeVersion26 ? xcode26AdditionalTargets : [])
)

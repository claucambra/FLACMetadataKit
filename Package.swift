// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FLACMetadataKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FLACMetadataKit",
            targets: ["FLACMetadataKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.9.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FLACMetadataKit",
            dependencies: ["Alamofire"]),
        .target(
            name: "TestCommon",
            dependencies: ["FLACMetadataKit"],
            path: "Tests/Common"),
        .testTarget(
            name: "FLACMetadataKitTests",
            dependencies: ["TestCommon", "FLACMetadataKit"],
            resources: [
                .process("Resources"),
              ]),
    ]
)

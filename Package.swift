// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "swift-httprequest",
	platforms: [
        .macOS(.v10_14),
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "HTTPRequesting",
            targets: ["HTTPRequesting"]
        ),
        .executable(
            name: "httpreq",
            targets: ["httpreq"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser",
                 from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "HTTPRequesting",
            dependencies: []
        ),
        .testTarget(
            name: "HTTPRequestingTests",
            dependencies: ["HTTPRequesting"]
        ),
        .target(
            name: "httpreq",
            dependencies: [
                "HTTPRequesting",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        )
    ]
)

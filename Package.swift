// swift-tools-version:4.1

import PackageDescription

#if os(macOS)
let clientPackage = "GEOS-mac"
#else
let clientPackage = "GEOS-linux"
#endif

let package = Package(
    name: "GEOSwift",
    products: [
        .library(name: "GEOSwift", targets: ["GEOSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/123FLO321/\(clientPackage).git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "GEOSwift", dependencies: ["GEOS"])
    ]
)

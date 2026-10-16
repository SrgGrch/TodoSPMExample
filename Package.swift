// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TodoApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "TodoApp",
            targets: ["TodoApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.0"),
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.10.0"),
        .package(url: "https://github.com/sindresorhus/Defaults", from: "8.0.0"),
        .package(url: "https://github.com/simibac/ConfettiSwiftUI", from: "3.0.0"),
        // Local copy of Kingfisher 8.13.0, patched to enable cross-import overlays
        // (see README: xtool does not resolve _PhotosUI_SwiftUI otherwise).
        .package(path: "Vendor/Kingfisher"),
    ],
    targets: [
        .target(
            name: "TodoApp",
            dependencies: [
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Defaults", package: "Defaults"),
                .product(name: "ConfettiSwiftUI", package: "ConfettiSwiftUI"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ]
        ),
    ]
)

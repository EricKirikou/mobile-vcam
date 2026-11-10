// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MobileVirtualCamera",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MobileVirtualCameraKit",
            targets: ["MobileVirtualCameraKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MobileVirtualCameraKit",
            path: "MobileVirtualCamera",
            exclude: ["Resources/Info.plist"]
        )
    ]
)


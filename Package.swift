// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "MyClipyMenuBar",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "MyClipyMenuBar", targets: ["MyClipyMenuBar"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MyClipyMenuBar",
            dependencies: [],
            path: "src"
        )
    ]
)
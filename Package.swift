// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Clipy",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .executable(name: "Clipy", targets: ["Clipy"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Clipy",
            dependencies: [],
            path: "src",
            sources: [
                "main.swift",
                "Constants.swift", 
                "MenuType.swift",
                "Extensions.swift",
                "Models.swift",
                "Services.swift",
                "PreferencesWindow.swift",
                "UIConstants.swift"
            ]
        )
    ]
)
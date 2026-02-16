// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ComposeLauncher",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "ComposeLauncherCore",
            dependencies: ["Yams"],
            path: "Sources/Core",
            exclude: ["Resources/Info.plist", "Resources/AppIcon.icns"]
        ),
        .executableTarget(
            name: "ComposeLauncher",
            dependencies: ["ComposeLauncherCore"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "ComposeLauncherTests",
            dependencies: ["ComposeLauncherCore"],
            path: "Tests"
        )
    ]
)

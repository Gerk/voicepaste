// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoicePaste",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "VoicePaste",
            dependencies: ["HotKey"],
            path: "Sources/VoicePaste",
            resources: [
                .copy("../../Resources/Info.plist")
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("Speech"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)

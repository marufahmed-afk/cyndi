// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cyndi",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Cyndi",
            resources: [
                .copy("Resources/Fonts")
            ],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)

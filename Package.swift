// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Deploybell",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Deploybell",
            path: "Sources"
        )
    ]
)

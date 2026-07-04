// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ChatMemoir",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "TimelineEngine", targets: ["TimelineEngine"]),
        .library(name: "StoryEngine", targets: ["StoryEngine"]),
        .library(name: "PresentationEngine", targets: ["PresentationEngine"]),
    ],
    dependencies: [
        .package(path: "../ChatImportKit"),
    ],
    targets: [
        .target(
            name: "TimelineEngine",
            dependencies: ["ChatImportKit"],
            path: "Sources/TimelineEngine"
        ),
        .testTarget(
            name: "TimelineEngineTests",
            dependencies: ["TimelineEngine"],
            path: "Tests/TimelineEngineTests"
        ),
        .target(
            name: "StoryEngine",
            dependencies: ["TimelineEngine"],
            path: "Sources/StoryEngine"
        ),
        .target(
            name: "PresentationEngine",
            dependencies: ["StoryEngine"],
            path: "Sources/PresentationEngine"
        ),
        .testTarget(
            name: "PresentationEngineTests",
            dependencies: ["PresentationEngine"],
            path: "Tests/PresentationEngineTests"
        ),
        .testTarget(
            name: "StoryEngineTests",
            dependencies: ["StoryEngine"],
            path: "Tests/StoryEngineTests"
        ),
    ]
)

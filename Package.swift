// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FloatLyrics",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "FloatLyrics", targets: ["FloatLyrics"])],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "3.1.0")
    ],
    targets: [
        .target(name: "LyricsCore"),
        .executableTarget(name: "FloatLyrics", dependencies: [
            "LyricsCore", .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
        ]),
        .testTarget(name: "LyricsCoreTests", dependencies: ["LyricsCore"]),
        .testTarget(name: "PlaybackTests", dependencies: ["FloatLyrics"])
    ]
)

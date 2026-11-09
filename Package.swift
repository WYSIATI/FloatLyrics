// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FloatLyrics",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "FloatLyrics", targets: ["FloatLyrics"])],
    targets: [
        .target(name: "LyricsCore"),
        .executableTarget(name: "FloatLyrics", dependencies: ["LyricsCore"]),
        .testTarget(name: "LyricsCoreTests", dependencies: ["LyricsCore"]),
        .testTarget(name: "PlaybackTests", dependencies: ["FloatLyrics"])
    ]
)

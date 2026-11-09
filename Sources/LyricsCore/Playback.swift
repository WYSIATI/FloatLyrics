import Foundation

public enum PlayerSource: String, CaseIterable, Codable, Sendable, Identifiable {
    case spotify, appleMusic
    public var id: String { rawValue }
    public var name: String { self == .spotify ? "Spotify" : "Apple Music" }
    public var bundleID: String { self == .spotify ? "com.spotify.client" : "com.apple.Music" }
}

public struct Track: Equatable, Codable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String
    public let duration: Double

    public init(id: String, title: String, artist: String, album: String, duration: Double) {
        self.id = id; self.title = title; self.artist = artist; self.album = album
        self.duration = duration.isFinite ? max(0, duration) : 0
    }

    // Metadata is included because some streamed/local tracks reuse an empty identifier.
    public var cacheKey: String { "\(id)|\(title)|\(artist)|\(album)|\(Int(duration))" }
}

public struct PlaybackSnapshot: Sendable {
    public let track: Track?
    public let isPlaying: Bool
    public let position: Double
    public let sampledAt: Date

    public init(track: Track?, isPlaying: Bool, position: Double, sampledAt: Date = Date()) {
        self.track = track; self.isPlaying = isPlaying
        self.position = position.isFinite ? max(0, position) : 0
        self.sampledAt = sampledAt
    }

    public func position(at date: Date) -> Double {
        let elapsed = isPlaying ? max(0, date.timeIntervalSince(sampledAt)) : 0
        let result = position + elapsed
        return track.map { $0.duration > 0 ? min(result, $0.duration) : result } ?? result
    }
}

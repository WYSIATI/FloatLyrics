import Foundation
import CryptoKit

public protocol LyricsTransport: Sendable {
    func get(_ request: URLRequest) async throws -> (Data, Int)
}

public struct NetworkTransport: LyricsTransport {
    public init() {}
    public func get(_ request: URLRequest) async throws -> (Data, Int) {
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
}

public enum LyricsError: LocalizedError {
    case notFound, server(Int), invalidResponse
    public var errorDescription: String? {
        switch self {
        case .notFound: "No lyrics found for this recording."
        case .server(429): "Lyrics service is busy. Try again shortly."
        case .server: "Lyrics service is unavailable. Try again."
        case .invalidResponse: "The lyrics service returned an unreadable response."
        }
    }
}

public struct LyricsRecord: Codable, Sendable {
    public let id: Int
    public let trackName: String
    public let artistName: String
    public let albumName: String?
    public let duration: Double
    public let instrumental: Bool
    public let plainLyrics: String?
    public let syncedLyrics: String?

    public var lyrics: Lyrics {
        Lyrics(lines: LRCParser.parse(syncedLyrics ?? ""), plainText: plainLyrics ?? "", instrumental: instrumental, recordID: id)
    }

    fileprivate var usableLyrics: Lyrics? {
        let result = lyrics
        let hasWords = result.lines.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return instrumental || hasWords || !result.plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? result : nil
    }

    public static func normalized(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }

    public static func lookupTitle(_ value: String) -> String {
        value.replacingOccurrences(of: #"\s*[\(\[]\s*(?:feat\.?|ft\.?|featuring)\s+[^\)\]]+[\)\]]"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func bestMatch(in records: [Self], for track: Track) -> Self? {
        records.filter {
            normalized(lookupTitle($0.trackName)) == normalized(lookupTitle(track.title)) &&
            normalized($0.artistName) == normalized(track.artist) &&
            (track.duration == 0 || abs($0.duration - track.duration) <= 4) &&
            $0.usableLyrics != nil
        }.max { a, b in
            func score(_ r: Self) -> Double {
                (normalized(r.albumName ?? "") == normalized(track.album) ? 20 : 0) +
                (r.lyrics.isSynced ? 10 : 0) - abs(r.duration - track.duration)
            }
            return score(a) < score(b)
        }
    }
}

public actor LRCLibClient {
    private let transport: any LyricsTransport
    private let cacheDirectory: URL?
    private var memory: [String: Lyrics] = [:]

    public init(transport: any LyricsTransport = NetworkTransport(), cacheDirectory: URL? = nil) {
        self.transport = transport; self.cacheDirectory = cacheDirectory
    }

    public func fetch(_ track: Track, force: Bool = false) async throws -> Lyrics {
        let key = track.cacheKey
        let filename = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined() + ".json"
        let file = cacheDirectory?.appendingPathComponent(filename)
        if !force {
            if let cached = memory[key] { return cached }
            if let file, let data = try? Data(contentsOf: file), let cached = try? JSONDecoder().decode(Lyrics.self, from: data) {
                memory[key] = cached; return cached
            }
        }
        var query = [URLQueryItem(name: "track_name", value: track.title), URLQueryItem(name: "artist_name", value: track.artist)]
        if !track.album.isEmpty { query.append(URLQueryItem(name: "album_name", value: track.album)) }
        if track.duration >= 1 && track.duration <= 3600 { query.append(URLQueryItem(name: "duration", value: String(Int(track.duration.rounded())))) }
        let (data, status) = try await request(path: "get", query: query)
        try Task.checkCancellation()
        var record: LyricsRecord?
        if status == 200 {
            record = try decode(LyricsRecord.self, from: data)
        } else if status != 404 { throw LyricsError.server(status) }
        if record?.usableLyrics == nil {
            let searchQuery = [URLQueryItem(name: "track_name", value: LyricsRecord.lookupTitle(track.title)), URLQueryItem(name: "artist_name", value: track.artist)]
            let (searchData, searchStatus) = try await request(path: "search", query: searchQuery)
            try Task.checkCancellation()
            guard searchStatus == 200 else { throw LyricsError.server(searchStatus) }
            record = LyricsRecord.bestMatch(in: try decode([LyricsRecord].self, from: searchData), for: track)
        }
        guard let lyrics = record?.usableLyrics else { throw LyricsError.notFound }
        memory[key] = lyrics
        if let file, let cacheDirectory {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            if let encoded = try? JSONEncoder().encode(lyrics) { try? encoded.write(to: file, options: .atomic) }
        }
        return lyrics
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try JSONDecoder().decode(type, from: data) }
        catch { throw LyricsError.invalidResponse }
    }

    private func request(path: String, query: [URLQueryItem]) async throws -> (Data, Int) {
        var components = URLComponents(string: "https://lrclib.net/api/\(path)")!
        components.queryItems = query
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        request.setValue("FloatLyrics (macOS; https://github.com/WYSIATI/FloatLyrics)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await transport.get(request)
    }
}

import Foundation

public struct AppVersion: Comparable, Sendable, CustomStringConvertible {
    private let components: [Int]

    public init?(_ value: String) {
        let raw = value.hasPrefix("v") ? String(value.dropFirst()) : value
        let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        var numbers: [Int] = []
        for part in parts {
            guard !part.isEmpty, part.utf8.allSatisfy({ (48...57).contains($0) }),
                  part.count == 1 || part.first != "0", let number = Int(part) else { return nil }
            numbers.append(number)
        }
        components = numbers
    }

    public var description: String { components.map(String.init).joined(separator: ".") }
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.components.lexicographicallyPrecedes(rhs.components)
    }
}

public struct UpdateRelease: Equatable, Sendable {
    public let version: AppVersion
    public let releaseURL: URL
    public let downloadURL: URL?
}

public enum UpdateCheckResult: Equatable, Sendable {
    case available(UpdateRelease)
    case upToDate
    case newerThanPublicRelease(latest: AppVersion)
}

public enum UpdateCheckError: LocalizedError, Equatable {
    case invalidCurrentVersion, invalidResponse, noPublicRelease, rateLimited, server(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidCurrentVersion: "The installed app's version could not be read. Open Releases to check manually."
        case .invalidResponse: "GitHub returned an unreadable release. Open Releases to check manually."
        case .noPublicRelease: "No public release is available yet. Please try again later."
        case .rateLimited: "GitHub is limiting update checks. Please try again later, or open Releases."
        case .server: "GitHub couldn't complete the update check. Please try again later, or open Releases."
        }
    }
}

public struct ReleaseUpdateClient: Sendable {
    public typealias Transport = @Sendable (URLRequest) async throws -> (Data, Int)
    public static let releasesURL = URL(string: "https://github.com/WYSIATI/FloatLyrics/releases")!
    private static let endpoint = URL(string: "https://api.github.com/repos/WYSIATI/FloatLyrics/releases/latest")!
    private let transport: Transport

    public init(transport: @escaping Transport = Self.fetch) { self.transport = transport }

    public func check(currentVersion: String) async throws -> UpdateCheckResult {
        guard let current = AppVersion(currentVersion) else { throw UpdateCheckError.invalidCurrentVersion }
        var request = URLRequest(url: Self.endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("FloatLyrics (macOS; https://github.com/WYSIATI/FloatLyrics)", forHTTPHeaderField: "User-Agent")
        let (data, status) = try await transport(request)
        try Task.checkCancellation()
        switch status {
        case 200: break
        case 403, 429: throw UpdateCheckError.rateLimited
        case 404: throw UpdateCheckError.noPublicRelease
        default: throw UpdateCheckError.server(status)
        }
        guard let release = try? JSONDecoder().decode(Release.self, from: data),
              !release.draft, !release.prerelease, let version = AppVersion(release.tag_name) else {
            throw UpdateCheckError.invalidResponse
        }
        guard version > current else {
            return version == current ? .upToDate : .newerThanPublicRelease(latest: version)
        }

        let candidates = ["Float-Lyrics-\(version).dmg", "Float-Lyrics.dmg", "FloatLyrics.dmg"]
        let installer = candidates.first { name in
            release.assets.contains { $0.name == name && $0.state == "uploaded" && $0.size > 0 }
        }
        // Only construct URLs within this repository, from validated tags and known asset names.
        let base = Self.releasesURL
        let info = UpdateRelease(version: version,
            releaseURL: base.appendingPathComponent("tag").appendingPathComponent(release.tag_name),
            downloadURL: installer.map {
                base.appendingPathComponent("download").appendingPathComponent(release.tag_name).appendingPathComponent($0)
            })
        return .available(info)
    }

    public static func fetch(_ request: URLRequest) async throws -> (Data, Int) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw UpdateCheckError.invalidResponse }
        return (data, response.statusCode)
    }

    private struct Release: Decodable {
        let tag_name: String
        let draft: Bool
        let prerelease: Bool
        let assets: [Asset]
    }
    private struct Asset: Decodable {
        let name: String
        let state: String
        let size: Int
    }
}

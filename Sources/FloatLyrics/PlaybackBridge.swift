import AppKit
import LyricsCore

struct PlaybackError: LocalizedError, Sendable {
    let code: Int
    let message: String
    var permissionDenied: Bool { code == -1743 || code == -1744 }
    var errorDescription: String? { message }
}

/// Apple events run serially off the UI thread. No shell processes, tokens, or account access.
final class PlaybackBridge: Sendable {
    private let queue = DispatchQueue(label: "app.floatlyrics.playback", qos: .userInitiated)

    static func script(for source: PlayerSource) -> String {
        let duration = source == .spotify ? "((duration of t) / 1000.0)" : "(duration of t)"
        let identifier = source == .spotify ? "(id of t as text)" : "(persistent ID of t as text)"
        return """
        with timeout of 3 seconds
            tell application id "\(source.bundleID)"
                if player state is stopped then return {"idle"}
                set t to current track
                return {name of t as text, artist of t as text, album of t as text, \(duration), player position, (player state is playing), \(identifier)}
            end tell
        end timeout
        """
    }

    func read(_ source: PlayerSource) async throws -> PlaybackSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let script = Self.script(for: source)
                var error: NSDictionary?
                guard let appleScript = NSAppleScript(source: script) else {
                    continuation.resume(throwing: PlaybackError(code: -1, message: "Could not prepare the playback connection.")); return
                }
                let result = appleScript.executeAndReturnError(&error)
                if let error {
                    let code = error[NSAppleScript.errorNumber] as? Int ?? -1
                    if code == -1728 || code == -600 {
                        continuation.resume(returning: PlaybackSnapshot(track: nil, isPlaying: false, position: 0)); return
                    }
                    continuation.resume(throwing: PlaybackError(code: code, message: error[NSAppleScript.errorMessage] as? String ?? "Could not read playback.")); return
                }
                guard result.numberOfItems == 7 else {
                    continuation.resume(returning: PlaybackSnapshot(track: nil, isPlaying: false, position: 0)); return
                }
                func string(_ index: Int) -> String { result.atIndex(index)?.stringValue ?? "" }
                func number(_ index: Int) -> Double {
                    result.atIndex(index)?.coerce(toDescriptorType: typeIEEE64BitFloatingPoint)?.doubleValue ?? 0
                }
                let track = Track(id: string(7), title: string(1), artist: string(2), album: string(3), duration: number(4))
                continuation.resume(returning: PlaybackSnapshot(track: track.title.isEmpty ? nil : track,
                    isPlaying: result.atIndex(6)?.booleanValue ?? false, position: number(5)))
            }
        }
    }
}

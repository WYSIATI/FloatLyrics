import AppKit
import Combine
import LyricsCore

@MainActor
final class AppModel: NSObject, ObservableObject {
    @Published var source: PlayerSource {
        didSet {
            guard source != oldValue else { return }
            UserDefaults.standard.set(source.rawValue, forKey: "source")
            denied = false; resetPlayback(); Task { await poll() }
        }
    }
    @Published var opacity: Double { didSet { UserDefaults.standard.set(opacity, forKey: "opacity") } }
    @Published var appearance: AppearancePreferences {
        didSet { if let data = try? JSONEncoder().encode(appearance) { UserDefaults.standard.set(data, forKey: "appearance.v1") } }
    }
    @Published var alwaysOnTop: Bool { didSet { UserDefaults.standard.set(alwaysOnTop, forKey: "alwaysOnTop") } }
    @Published var clickThrough = false
    @Published var notchMode: Bool { didSet { UserDefaults.standard.set(notchMode, forKey: "notchMode") } }
    @Published var fontSize: Double { didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") } }
    @Published var timingAdjustment: Double = 0
    @Published private(set) var snapshot = PlaybackSnapshot(track: nil, isPlaying: false, position: 0)
    @Published private(set) var lyrics: Lyrics?
    @Published private(set) var loading = false
    @Published private(set) var lyricsMessage: String?
    @Published private(set) var connectionMessage: String?
    @Published private(set) var denied = false
    let demo: Bool
    private let bridge = PlaybackBridge()
    private let client: LRCLibClient
    private var monitoring: Task<Void, Never>?
    private var fetching: Task<Void, Never>?
    private var reading = false
    private var generation = 0

    override init() {
        let defaults = UserDefaults.standard
        source = PlayerSource(rawValue: defaults.string(forKey: "source") ?? "") ?? .spotify
        appearance = .restore(defaults.data(forKey: "appearance.v1"))
        opacity = defaults.object(forKey: "opacity").map { _ in min(1, max(0.15, defaults.double(forKey: "opacity"))) } ?? 0.70
        alwaysOnTop = defaults.object(forKey: "alwaysOnTop") == nil || defaults.bool(forKey: "alwaysOnTop")
        notchMode = defaults.bool(forKey: "notchMode")
        fontSize = defaults.object(forKey: "fontSize").map { _ in min(34, max(18, defaults.double(forKey: "fontSize"))) } ?? 26
        demo = ProcessInfo.processInfo.arguments.contains("--demo")
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("app.floatlyrics.desktop/lyrics", isDirectory: true)
        client = LRCLibClient(cacheDirectory: caches)
        super.init()
    }

    func start() {
        if demo {
            snapshot = PlaybackSnapshot(track: Track(id: "demo", title: "A little room to sing", artist: "FloatLyrics · Preview", album: "Original demo", duration: 180), isPlaying: true, position: 8)
            lyrics = Lyrics(lines: [
                .init(time: 0, text: "Let the day move softly"), .init(time: 7, text: "There's a little room to sing"),
                .init(time: 15, text: "Keep a melody beside you"), .init(time: 23, text: "See what a moment can bring"),
                .init(time: 31, text: "Let the day move softly"), .init(time: 39, text: "There's a little room to sing")
            ], plainText: "")
            return
        }
        for name in ["com.spotify.client.PlaybackStateChanged", "com.apple.Music.playerInfo"] {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(playbackChanged), name: NSNotification.Name(name), object: nil)
        }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(playbackChanged), name: NSWorkspace.didWakeNotification, object: nil)
        monitoring = Task { [weak self] in
            while !Task.isCancelled {
                await self?.poll()
                try? await Task.sleep(for: .milliseconds(750))
            }
        }
    }

    @objc private func playbackChanged(_ notification: Notification) { Task { await poll() } }

    private func resetPlayback() {
        generation += 1; fetching?.cancel(); fetching = nil
        snapshot = PlaybackSnapshot(track: nil, isPlaying: false, position: 0)
        lyrics = nil; lyricsMessage = nil; loading = false; connectionMessage = nil
        timingAdjustment = 0
    }

    private func poll() async {
        guard !reading, !demo, !denied else { return }
        guard !NSRunningApplication.runningApplications(withBundleIdentifier: source.bundleID).isEmpty else {
            if snapshot.track != nil { resetPlayback() }
            connectionMessage = "Open \(source.name) and play a song."
            return
        }
        reading = true
        let requestedSource = source
        defer { reading = false }
        do {
            let next = try await bridge.read(requestedSource)
            guard requestedSource == source else { return }
            diagnostic("playback source=\(requestedSource.rawValue) position=\(next.position) duration=\(next.track?.duration ?? 0) playing=\(next.isPlaying)")
            connectionMessage = nil
            let changed = next.track?.cacheKey != snapshot.track?.cacheKey
            snapshot = next
            if changed {
                generation += 1; fetching?.cancel(); lyrics = nil; lyricsMessage = nil; loading = false
                timingAdjustment = 0
                if let track = next.track { fetchLyrics(track) }
            }
        } catch {
            guard requestedSource == source else { return }
            resetPlayback()
            if let failure = error as? PlaybackError, failure.permissionDenied {
                denied = true
                connectionMessage = "Allow FloatLyrics to read \(source.name) in System Settings → Privacy & Security → Automation."
            } else { connectionMessage = "Playback connection interrupted. Reconnecting to \(source.name)…" }
        }
    }

    private func fetchLyrics(_ track: Track, force: Bool = false) {
        fetching?.cancel(); generation += 1
        let requestGeneration = generation
        loading = true; lyricsMessage = nil
        fetching = Task { [weak self, client] in
            do {
                let result = try await client.fetch(track, force: force)
                guard let self, !Task.isCancelled, self.generation == requestGeneration else { return }
                self.lyrics = result; self.loading = false
                self.diagnostic("lyrics synced=\(result.isSynced) lines=\(result.lines.count) first=\(result.lines.first?.time ?? -1)")
            } catch {
                guard let self, !Task.isCancelled, self.generation == requestGeneration else { return }
                self.loading = false
                self.lyricsMessage = (error as? LyricsError)?.localizedDescription ?? "Couldn't reach LRCLIB. Check your connection and retry."
            }
        }
    }

    func retry() {
        denied = false
        if let track = snapshot.track { fetchLyrics(track, force: true) }
        else { Task { await poll() } }
    }

    func openPlayer() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: source.bundleID) else {
            connectionMessage = "Install the \(source.name) desktop app to connect."; return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func openAutomationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") { NSWorkspace.shared.open(url) }
    }

    func line(at date: Date) -> String {
        if denied { return "Allow playback access · expand to connect" }
        if lyricsMessage != nil { return "Lyrics unavailable · expand to retry" }
        guard let lyrics else { return loading ? "Finding the words…" : (snapshot.track?.title ?? "Your music, a little closer.") }
        if lyrics.instrumental { return "Instrumental ♪" }
        guard lyrics.isSynced else { return "Unsynced lyrics · open the floating view" }
        guard let index = lyrics.activeIndex(at: snapshot.position(at: date), adjustment: timingAdjustment) else { return "♪" }
        return lyrics.lines[index].text.isEmpty ? "♪" : lyrics.lines[index].text
    }

    private func diagnostic(_ message: String) {
        guard ProcessInfo.processInfo.arguments.contains("--diagnostics") else { return }
        FileHandle.standardOutput.write(Data((message + "\n").utf8))
    }
}

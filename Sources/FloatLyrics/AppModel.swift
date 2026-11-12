import AppKit
import Combine
import KeyboardShortcuts
import LyricsCore

@MainActor
final class AppModel: NSObject, ObservableObject {
    @Published var source: PlayerSource {
        didSet {
            guard source != oldValue else { return }
            defaults.set(source.rawValue, forKey: "source")
            denied = false; resetPlayback(); Task { await poll() }
        }
    }
    @Published var opacity: Double { didSet { defaults.set(opacity, forKey: "opacity") } }
    @Published var appearance: AppearancePreferences {
        didSet { if let data = try? JSONEncoder().encode(appearance) { defaults.set(data, forKey: "appearance.v1") } }
    }
    @Published var alwaysOnTop: Bool { didSet { defaults.set(alwaysOnTop, forKey: "alwaysOnTop") } }
    @Published var clickThrough = false
    @Published var notchMode: Bool {
        didSet {
            guard notchMode != oldValue else { return }
            defaults.set(notchMode, forKey: "notchMode")
            lyricsHidden = false
        }
    }
    @Published private(set) var lyricsHidden = false
    @Published var windowShortcut: KeyboardShortcuts.Shortcut? {
        didSet {
            if let windowShortcut, let data = try? JSONEncoder().encode(windowShortcut) {
                defaults.set(data, forKey: "windowShortcut.v1")
            } else {
                defaults.removeObject(forKey: "windowShortcut.v1")
            }
        }
    }
    @Published var fontSize: Double { didSet { defaults.set(fontSize, forKey: "fontSize") } }
    @Published var timingAdjustment: Double = 0
    @Published private(set) var snapshot = PlaybackSnapshot(track: nil, isPlaying: false, position: 0)
    @Published private(set) var lyrics: Lyrics?
    @Published private(set) var loading = false
    @Published private(set) var lyricsMessage: String?
    @Published private(set) var connectionMessage: String?
    @Published private(set) var denied = false
    let demo: Bool
    let visualPreview: Bool
    private let defaults: UserDefaults
    private let bridge = PlaybackBridge()
    private let client: LRCLibClient
    private var monitoring: Task<Void, Never>?
    private var fetching: Task<Void, Never>?
    private var reading = false
    private var generation = 0

    init(defaults suppliedDefaults: UserDefaults? = nil, arguments: [String] = ProcessInfo.processInfo.arguments) {
        demo = arguments.contains("--demo")
        visualPreview = demo || arguments.contains("--recording-preview")
        // Visual previews must not overwrite the listener's real preferences.
        defaults = suppliedDefaults ?? (visualPreview ? UserDefaults(suiteName: "app.floatlyrics.preview")! : .standard)
        let defaults = self.defaults
        source = PlayerSource(rawValue: defaults.string(forKey: "source") ?? "") ?? .spotify
        appearance = .restore(defaults.data(forKey: "appearance.v1"))
        opacity = defaults.object(forKey: "opacity").map { _ in min(1, max(0.15, defaults.double(forKey: "opacity"))) } ?? 0.70
        alwaysOnTop = defaults.object(forKey: "alwaysOnTop") == nil || defaults.bool(forKey: "alwaysOnTop")
        notchMode = defaults.bool(forKey: "notchMode")
        windowShortcut = defaults.data(forKey: "windowShortcut.v1").flatMap {
            try? JSONDecoder().decode(KeyboardShortcuts.Shortcut.self, from: $0)
        }
        fontSize = defaults.object(forKey: "fontSize").map { _ in min(34, max(18, defaults.double(forKey: "fontSize"))) } ?? 26
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("app.floatlyrics.desktop/lyrics", isDirectory: true)
        client = LRCLibClient(cacheDirectory: caches)
        super.init()
    }

    var visibilityMenuTitle: String {
        if notchMode { return lyricsHidden ? "Show Dynamic Island" : "Hide Dynamic Island" }
        return lyricsHidden ? "Show Window" : "Hide Window"
    }

    func hideLyrics() { lyricsHidden = true }
    func toggleLyricsVisibility() { lyricsHidden.toggle() }

    func start() {
        if demo {
            let arguments = ProcessInfo.processInfo.arguments
            let position = arguments.firstIndex(of: "--demo-position").flatMap { index in
                arguments.indices.contains(index + 1) ? Double(arguments[index + 1]) : nil
            } ?? 8
            snapshot = PlaybackSnapshot(track: Track(id: "demo", title: "Desktop lyrics", artist: "Float Lyrics · Preview", album: "Product demo", duration: 180), isPlaying: true, position: min(39, max(0, position.isFinite ? position : 8)))
            lyrics = Lyrics(lines: [
                .init(time: 0, text: "Play a song. See the words."), .init(time: 7, text: "Your music, in sync."),
                .init(time: 15, text: "Lyrics, right on your desktop"), .init(time: 23, text: "Follow along without switching apps"),
                .init(time: 31, text: "Try the window or your notch"), .init(time: 39, text: "Make the lyrics feel like yours")
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
                connectionMessage = "Allow Float Lyrics to read \(source.name) in System Settings → Privacy & Security → Automation."
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

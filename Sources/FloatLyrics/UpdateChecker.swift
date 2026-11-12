import AppKit
import Combine
import LyricsCore
import OSLog

struct UpdateNotice: Equatable {
    let title: String
    let message: String
    var actionTitle: String?
    var actionURL: URL?
    var releaseURL: URL?

    static func result(_ result: UpdateCheckResult, currentVersion: String) -> Self {
        switch result {
        case .available(let release):
            return .init(title: "Float Lyrics \(release.version) is available",
                message: "You're using \(currentVersion). Download the update, quit Float Lyrics, then replace the app in Applications. Your settings are kept.",
                actionTitle: release.downloadURL == nil ? "View Release…" : "Download Update…",
                actionURL: release.downloadURL ?? release.releaseURL,
                releaseURL: release.downloadURL == nil ? nil : release.releaseURL)
        case .upToDate:
            return .init(title: "You're up to date", message: "Float Lyrics \(currentVersion) is the latest public release.")
        case .newerThanPublicRelease(let latest):
            return .init(title: "You're running a newer build",
                message: "You're using Float Lyrics \(currentVersion). The latest public release is \(latest). No update is needed.")
        }
    }

    static func failure(_ error: Error) -> Self {
        let message = (error as? UpdateCheckError)?.localizedDescription
            ?? "Couldn't connect to GitHub. Check your internet connection and try again, or open Releases."
        return .init(title: "Couldn't check for updates", message: message,
                     actionTitle: "Open Releases…", actionURL: ReleaseUpdateClient.releasesURL)
    }
}

@MainActor
final class UpdateChecker: ObservableObject {
    @Published private(set) var isChecking = false
    private let client: ReleaseUpdateClient
    private let currentVersion: String
    private let present: @MainActor (UpdateNotice) -> Void
    private var task: Task<Void, Never>?
    private let logger = Logger(subsystem: "app.floatlyrics.desktop", category: "Updates")

    init(client: ReleaseUpdateClient = .init(),
         currentVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
         present: @escaping @MainActor (UpdateNotice) -> Void = UpdateChecker.showNotice) {
        self.client = client; self.currentVersion = currentVersion; self.present = present
    }

    deinit { task?.cancel() }

    func checkForUpdates() {
        guard !isChecking else { return }
        isChecking = true
        logger.info("User requested an update check")
        task = Task { [weak self] in
            guard let self else { return }
            defer { isChecking = false; task = nil }
            do {
                let result = try await client.check(currentVersion: currentVersion)
                guard !Task.isCancelled else { return }
                logger.info("Update check completed")
                present(.result(result, currentVersion: currentVersion))
            } catch {
                guard !Task.isCancelled else { return }
                logger.error("Update check failed: \(String(describing: error), privacy: .private)")
                present(.failure(error))
            }
        }
    }

    private static func showNotice(_ notice: UpdateNotice) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = notice.title
        alert.informativeText = notice.message
        if let actionTitle = notice.actionTitle { alert.addButton(withTitle: actionTitle) }
        let dismiss = alert.addButton(withTitle: notice.actionURL == nil ? "OK" : "Later")
        if notice.actionURL != nil { dismiss.keyEquivalent = "\u{1b}" }
        if notice.releaseURL != nil { alert.addButton(withTitle: "Release Notes…") }
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn, let url = notice.actionURL {
            NSWorkspace.shared.open(url)
        } else if response == .alertThirdButtonReturn, let url = notice.releaseURL {
            NSWorkspace.shared.open(url)
        }
    }
}

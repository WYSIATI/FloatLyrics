import AppKit
import SwiftUI
import Combine
import KeyboardShortcuts
import LyricsCore
import OSLog

private final class LyricsPanel: NSPanel {
    var anchorsToScreenTop = false
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        anchorsToScreenTop ? frameRect : super.constrainFrameRect(frameRect, to: screen)
    }
}

@MainActor
final class WindowCoordinator: NSObject, NSWindowDelegate, NSMenuDelegate {
    let model = AppModel()
    private let updates = UpdateChecker()
    private var floating: LyricsPanel!
    private var notch: LyricsPanel!
    private var island: IslandPresentation!
    private var statusItem: NSStatusItem!
    private var preferences: NSWindow?
    private var subscriptions = Set<AnyCancellable>()
    private var shortcutTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "app.floatlyrics.desktop", category: "WindowPresentation")

    deinit { shortcutTask?.cancel() }

    func start() {
        floating = makePanel(size: FloatingView.size)
        floating.isMovableByWindowBackground = true
        floating.delegate = self
        floating.contentView = NSHostingView(rootView: FloatingView(model: model,
            hide: { [weak self] in self?.model.hideLyrics() }, showPreferences: { [weak self] in self?.showPreferences() },
            quit: { [weak self] in self?.quit() }))
        restoreFloatingPosition()
        notch = makePanel(size: NSSize(width: 580, height: 220))
        notch.hasShadow = false
        notch.anchorsToScreenTop = true
        notch.isMovable = false
        notch.acceptsMouseMovedEvents = true
        notch.becomesKeyOnlyIfNeeded = true
        let display = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main ?? NSScreen.screens[0]
        island = IslandPresentation(geometry: NotchGeometry(screen: display, preferredWidth: model.appearance.islandWidth))
        notch.contentView = NSHostingView(rootView: NotchView(model: model, presentation: island,
            quit: { [weak self] in self?.quit() }))
        island.track(panel: notch, app: model)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = BrandMark.menuBarImage
        statusItem.button?.toolTip = "Float Lyrics · lyrics beside your work"
        rebuildMenu()
        // The native glass background changes opacity; lyrics retain full contrast.
        floating.alphaValue = 1
        model.$alwaysOnTop.sink { [weak self] value in
            self?.floating.level = value ? .floating : .normal
            DispatchQueue.main.async { self?.rebuildMenu() }
        }.store(in: &subscriptions)
        model.$clickThrough.sink { [weak self] value in
            self?.floating.ignoresMouseEvents = value; self?.notch.ignoresMouseEvents = value
            DispatchQueue.main.async { self?.rebuildMenu() }
        }.store(in: &subscriptions)
        model.$notchMode.combineLatest(model.$lyricsHidden).dropFirst().sink { [weak self] _ in
            // @Published emits before the value changes. Apply the new model state on the next turn.
            DispatchQueue.main.async { self?.updatePresentation(); self?.rebuildMenu() }
        }.store(in: &subscriptions)
        model.$windowShortcut.removeDuplicates().sink { [weak self] shortcut in
            self?.registerShortcut(shortcut)
            DispatchQueue.main.async { self?.rebuildMenu() }
        }.store(in: &subscriptions)
        updates.$isChecking.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.rebuildMenu() }
        }.store(in: &subscriptions)
        model.$source.dropFirst().sink { [weak self] _ in DispatchQueue.main.async { self?.rebuildMenu() } }.store(in: &subscriptions)
        model.$appearance.map(\.islandWidth).removeDuplicates().dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { if self?.model.notchMode == true { self?.positionNotch(reset: false) } }
        }.store(in: &subscriptions)
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appearanceRequested(_:)), name: NSNotification.Name("FloatLyrics.showAppearance"), object: nil)
        updatePresentation()
        model.start()
    }

    private func makePanel(size: NSSize) -> LyricsPanel {
        let panel = LyricsPanel(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false; panel.isOpaque = false; panel.backgroundColor = .clear
        panel.hasShadow = true; panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.animationBehavior = .utilityWindow
        panel.isFloatingPanel = true
        panel.title = "Float Lyrics"
        return panel
    }

    private func restoreFloatingPosition() {
        if model.visualPreview,
           let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main {
            let area = screen.visibleFrame
            floating.setFrameOrigin(NSPoint(x: area.maxX - FloatingView.size.width - 36,
                                            y: area.minY + 70))
            return
        }
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let area = screen?.visibleFrame else { return }
        var saved = UserDefaults.standard.string(forKey: "floatingFrame").map(NSRectFromString)
        saved?.size = FloatingView.size
        if let saved, NSScreen.screens.contains(where: { $0.visibleFrame.contains(saved) }) {
            floating.setFrame(saved, display: false)
        } else {
            floating.setFrameOrigin(NSPoint(x: area.maxX - FloatingView.size.width - 36, y: area.minY + 70))
        }
    }

    private func updatePresentation() {
        logger.debug("Updating lyrics presentation: hidden=\(self.model.lyricsHidden), island=\(self.model.notchMode)")
        guard !model.lyricsHidden else { island.close(); floating.orderOut(nil); notch.orderOut(nil); return }
        if model.notchMode {
            floating.orderOut(nil)
            positionNotch()
            notch.orderFrontRegardless()
        } else {
            notch.orderOut(nil)
            floating.orderFrontRegardless()
        }
    }

    private func positionNotch(reset: Bool = true) {
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? floating.screen ?? NSScreen.main else { return }
        island.geometry = NotchGeometry(screen: screen, preferredWidth: model.appearance.islandWidth)
        if reset { island.close() }
        notch.alphaValue = 1
        notch.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        notch.setFrame(island.geometry.windowFrame, display: true)
    }

    @objc private func screenChanged() { restoreFloatingPosition(); if model.notchMode { positionNotch() } }
    @objc private func appearanceRequested(_ notification: Notification) { showPreferences() }

    func windowDidMove(_ notification: Notification) {
        guard !model.visualPreview else { return }
        UserDefaults.standard.set(NSStringFromRect(floating.frame), forKey: "floatingFrame")
    }

    @objc private func toggleVisibility() { model.toggleLyricsVisibility() }
    @objc private func toggleNotch() { model.notchMode.toggle() }
    @objc private func chooseSource(_ sender: NSMenuItem) { if let raw = sender.representedObject as? String, let source = PlayerSource(rawValue: raw) { model.source = source } }
    @objc private func retry() { model.retry() }
    @objc private func openPlayer() { model.openPlayer() }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func checkForUpdates() { updates.checkForUpdates() }

    @objc private func showPreferences() {
        if preferences == nil {
            let window = makePanel(size: PreferencesView.size)
            window.styleMask.insert(.closable)
            window.isMovableByWindowBackground = true
            window.title = "Float Lyrics Settings"; window.isReleasedWhenClosed = false
            window.center(); preferences = window
        }
        // Each opening starts at the small Settings index; details stay one level deeper.
        preferences?.contentView = NSHostingView(rootView: PreferencesView(model: model, updates: updates,
            dismiss: { [weak self] in self?.preferences?.orderOut(nil) },
            resize: { [weak self] height in self?.resizePreferences(height: height) }))
        resizePreferences(height: PreferencesView.size.height)
        preferences?.level = .floating
        preferences?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func resizePreferences(height: CGFloat) {
        guard let window = preferences else { return }
        var frame = window.frame
        frame.origin.y += frame.height - height
        frame.size.height = height
        window.setFrame(frame, display: true)
    }

    private func registerShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) {
        logger.debug("Updating global visibility shortcut: assigned=\(shortcut != nil)")
        shortcutTask?.cancel()
        shortcutTask = nil
        guard let shortcut else { return }
        shortcutTask = Task { [weak self] in
            // Key-up toggles once, even when the user holds the combination down.
            for await event in KeyboardShortcuts.events(for: shortcut) where event == .keyUp {
                guard !Task.isCancelled else { return }
                self?.model.toggleLyricsVisibility()
            }
        }
    }

    // Let the menu handle its displayed key equivalent without a second global callback.
    func menuWillOpen(_ menu: NSMenu) { KeyboardShortcuts.isEnabled = false }
    func menuDidClose(_ menu: NSMenu) { KeyboardShortcuts.isEnabled = true }

    private func rebuildMenu() {
        guard statusItem != nil else { return }
        let menu = NSMenu()
        menu.delegate = self
        let visibility = add(model.visibilityMenuTitle, action: #selector(toggleVisibility), menu: menu)
        visibility.setShortcut(model.windowShortcut)
        add("Dynamic Island", action: #selector(toggleNotch), key: "n", checked: model.notchMode, menu: menu)
        let playerMenu = NSMenu()
        for source in PlayerSource.allCases {
            let item = add(source.name, action: #selector(chooseSource(_:)), checked: source == model.source, menu: playerMenu)
            item.representedObject = source.rawValue
        }
        playerMenu.addItem(.separator())
        add("Open \(model.source.name)", action: #selector(openPlayer), menu: playerMenu)
        add("Reconnect / Refresh Lyrics", action: #selector(retry), menu: playerMenu)
        let playerItem = NSMenuItem(title: "Music Player", action: nil, keyEquivalent: "")
        playerItem.submenu = playerMenu; menu.addItem(playerItem)
        menu.addItem(.separator())
        add("Settings…", action: #selector(showPreferences), key: ",", menu: menu)
        let update = add(updates.isChecking ? "Checking for Updates…" : "Check for Updates…", action: #selector(checkForUpdates), menu: menu)
        update.isEnabled = !updates.isChecking
        menu.autoenablesItems = false
        add("Quit Float Lyrics", action: #selector(quit), key: "q", menu: menu)
        statusItem.menu = menu
    }

    @discardableResult private func add(_ title: String, action: Selector, key: String = "", checked: Bool = false, menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self; item.state = checked ? .on : .off; menu.addItem(item); return item
    }
}

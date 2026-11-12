import AppKit
import KeyboardShortcuts
import OSLog
import SwiftUI

@MainActor
enum ShortcutValidation {
    private static let functionKeys: Set<KeyboardShortcuts.Key> = [
        .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10,
        .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19, .f20
    ]

    static func rejectionReason(for shortcut: KeyboardShortcuts.Shortcut,
                                current: KeyboardShortcuts.Shortcut?, menus: [NSMenu],
                                takenBySystem: Bool) -> String? {
        let primaryModifiers: NSEvent.ModifierFlags = [.command, .control, .option]
        if shortcut.modifiers.isDisjoint(with: primaryModifiers),
           !functionKeys.contains(shortcut.key ?? .space) {
            return "Add Command (⌘), Control (⌃), or Option (⌥). Shift plus a letter alone cannot be used. For example, try Control + Shift + H."
        }
        if takenBySystem {
            return "This shortcut is already used by macOS. Choose another combination, or change it in System Settings → Keyboard → Keyboard Shortcuts."
        }
        guard shortcut != current else { return nil }
        let probe = NSMenuItem()
        probe.setShortcut(shortcut)
        for menu in menus {
            if let title = conflictingItem(in: menu, key: probe.keyEquivalent, modifiers: probe.keyEquivalentModifierMask) {
                return "This shortcut is already used by “\(title)” in the app menu. Choose a different combination."
            }
        }
        return nil
    }

    private static func conflictingItem(in menu: NSMenu, key: String, modifiers: NSEvent.ModifierFlags) -> String? {
        for item in menu.items {
            if let submenu = item.submenu, let title = conflictingItem(in: submenu, key: key, modifiers: modifiers) {
                return title
            }
            guard !key.isEmpty, !item.keyEquivalent.isEmpty else { continue }
            var itemModifiers = item.keyEquivalentModifierMask
            if item.keyEquivalent != item.keyEquivalent.lowercased() { itemModifiers.insert(.shift) }
            if item.keyEquivalent.lowercased() == key.lowercased(), itemModifiers == modifiers { return item.title }
        }
        return nil
    }
}

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: KeyboardShortcuts.Shortcut?
    var menus: () -> [NSMenu]

    func makeNSView(context: Context) -> ShortcutRecorderHost {
        ShortcutRecorderHost(shortcut: shortcut, menus: menus, onChange: { shortcut = $0 })
    }

    func updateNSView(_ view: ShortcutRecorderHost, context: Context) {
        view.onChange = { shortcut = $0 }
        view.menus = menus
        view.recorder.shortcut = shortcut
        view.appearance = NSAppearance(named: context.environment.colorScheme == .dark ? .darkAqua : .aqua)
    }

    static func dismantleNSView(_ view: ShortcutRecorderHost, coordinator: ()) { view.stopMonitoring() }
}

/// Keeps the standard recorder's interaction while capturing Command equivalents before menus.
final class ShortcutRecorderHost: NSView {
    private let initialShortcut: KeyboardShortcuts.Shortcut?
    private(set) lazy var recorder = KeyboardShortcuts.RecorderCocoa(shortcut: initialShortcut) { [weak self] value in
        self?.onChange(value)
    }
    var onChange: (KeyboardShortcuts.Shortcut?) -> Void
    var menus: () -> [NSMenu]
    var systemConflict: (KeyboardShortcuts.Shortcut) -> Bool = { $0.isTakenBySystem }
    var presentError: ((String) -> Void)?
    private var monitor: Any?
    private let logger = Logger(subsystem: "app.floatlyrics.desktop", category: "ShortcutRecorder")

    init(shortcut: KeyboardShortcuts.Shortcut?, menus: @escaping () -> [NSMenu],
         onChange: @escaping (KeyboardShortcuts.Shortcut?) -> Void) {
        self.menus = menus
        self.onChange = onChange
        initialShortcut = shortcut
        super.init(frame: NSRect(x: 0, y: 0, width: 130, height: 24))
        // Custom validation supplies the same precise explanation for both event paths.
        recorder.conflictPolicy = .allowAll
        recorder.validateShortcut = { [weak self] value in
            if let reason = self?.rejectionReason(value) { return .disallow(reason: reason) }
            return .allow
        }
        addSubview(recorder)
        recorder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recorder.leadingAnchor.constraint(equalTo: leadingAnchor), recorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            recorder.topAnchor.constraint(equalTo: topAnchor), recorder.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        recorder.setAccessibilityLabel("Show or hide lyrics shortcut")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    isolated deinit { stopMonitoring() }
    override var intrinsicContentSize: NSSize { recorder.intrinsicContentSize }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === window else { return event }
            return captureCommand(event) ? nil : event
        }
    }

    func stopMonitoring() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    func captureCommand(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown, event.modifierFlags.contains(.command),
              let editor = recorder.currentEditor(), window?.firstResponder === editor,
              let shortcut = KeyboardShortcuts.Shortcut(event: event) else { return false }
        guard !event.isARepeat else { return true }
        if let reason = rejectionReason(shortcut) {
            logger.debug("Rejected a conflicting or unsupported shortcut")
            if let presentError { presentError(reason) }
            else { showError(reason) }
            return true
        }
        recorder.shortcut = shortcut
        onChange(shortcut)
        window?.makeFirstResponder(nil)
        logger.debug("Recorded a Command shortcut")
        return true
    }

    private func rejectionReason(_ value: KeyboardShortcuts.Shortcut) -> String? {
        ShortcutValidation.rejectionReason(for: value, current: recorder.shortcut,
            menus: menus(), takenBySystem: systemConflict(value))
    }

    private func showError(_ message: String) {
        guard let window else { return }
        window.makeFirstResponder(nil)
        let alert = NSAlert()
        alert.messageText = "Choose a different shortcut"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window) { [weak self] _ in
            guard let self else { return }
            self.window?.makeFirstResponder(recorder)
        }
    }
}

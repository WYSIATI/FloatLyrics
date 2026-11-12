import AppKit
import KeyboardShortcuts
import SwiftUI
import XCTest
@testable import FloatLyrics

@MainActor
final class SettingsRecorderTests: XCTestCase {
    func testCommandShiftHIsCapturedBySettingsKeyEquivalentRoute() async throws {
        _ = NSApplication.shared
        let window = SettingsWindow(size: NSSize(width: 350, height: 180))
        defer { window.close() }
        XCTAssertTrue(window.canBecomeKey)
        XCTAssertTrue(window.canBecomeMain)
        XCTAssertFalse(window.styleMask.contains(.nonactivatingPanel))
        var captured: KeyboardShortcuts.Shortcut?
        let host = ShortcutRecorderHost(shortcut: nil, menus: { [] }) { captured = $0 }
        host.systemConflict = { _ in false }
        window.contentView?.addSubview(host)
        host.frame = NSRect(x: 20, y: 20, width: 130, height: 24)
        await Task.yield()
        XCTAssertTrue(window.makeFirstResponder(host.recorder))
        await Task.yield()
        let shortcut = KeyboardShortcuts.Shortcut(.h, modifiers: [.command, .shift])
        let event = try keyEvent(shortcut, window: window)
        XCTAssertTrue(window.performKeyEquivalent(with: event))
        XCTAssertEqual(captured, shortcut)
        XCTAssertEqual(host.recorder.shortcut, shortcut)
    }

    func testNativeControlShortcutStillInvokesBindingAndDeleteClearsIt() async throws {
        _ = NSApplication.shared
        let window = SettingsWindow(size: NSSize(width: 350, height: 180))
        defer { window.close() }
        var changes: [KeyboardShortcuts.Shortcut?] = []
        let host = ShortcutRecorderHost(shortcut: nil, menus: { [] }) { changes.append($0) }
        host.systemConflict = { _ in false }
        window.contentView?.addSubview(host)
        await Task.yield()
        XCTAssertTrue(window.makeFirstResponder(host.recorder))
        await Task.yield()
        let shortcut = KeyboardShortcuts.Shortcut(.h, modifiers: [.control, .shift])
        NSApp.sendEvent(try keyEvent(shortcut, window: window))
        XCTAssertEqual(changes, [shortcut])
        await Task.yield()
        XCTAssertTrue(window.makeFirstResponder(host.recorder))
        await Task.yield()
        NSApp.sendEvent(try keyEvent(.init(.delete), window: window, characters: "\u{7f}"))
        XCTAssertEqual(changes, [shortcut, nil])
    }

    func testCommandMenuConflictReportsTheActionInsteadOfSaving() async throws {
        _ = NSApplication.shared
        let shortcut = KeyboardShortcuts.Shortcut(.h, modifiers: [.command, .shift])
        let menu = NSMenu()
        let item = NSMenuItem(title: "Existing Action", action: nil, keyEquivalent: "H")
        item.keyEquivalentModifierMask = .command
        menu.addItem(item)
        let window = SettingsWindow(size: NSSize(width: 350, height: 180))
        defer { window.close() }
        var captured: KeyboardShortcuts.Shortcut?
        var message: String?
        let host = ShortcutRecorderHost(shortcut: nil, menus: { [menu] }) { captured = $0 }
        host.systemConflict = { _ in false }
        host.presentError = { message = $0 }
        window.contentView?.addSubview(host)
        await Task.yield()
        XCTAssertTrue(window.makeFirstResponder(host.recorder))
        await Task.yield()
        XCTAssertTrue(window.performKeyEquivalent(with: try keyEvent(shortcut, window: window)))
        XCTAssertNil(captured)
        XCTAssertTrue(try XCTUnwrap(message).contains("Existing Action"))
    }

    func testRerecordingCurrentCommandShortcutAndCancellingKeepTheSavedValue() async throws {
        _ = NSApplication.shared
        let shortcut = KeyboardShortcuts.Shortcut(.h, modifiers: [.command, .shift])
        let menu = NSMenu()
        let item = NSMenuItem(title: "Show Window", action: nil, keyEquivalent: "")
        item.setShortcut(shortcut)
        menu.addItem(item)
        let window = SettingsWindow(size: NSSize(width: 350, height: 180))
        defer { window.makeFirstResponder(nil); window.close() }
        var changes: [KeyboardShortcuts.Shortcut?] = []
        let host = ShortcutRecorderHost(shortcut: shortcut, menus: { [menu] }) { changes.append($0) }
        host.systemConflict = { _ in false }
        window.contentView?.addSubview(host)
        await Task.yield()
        XCTAssertTrue(window.makeFirstResponder(host.recorder))
        await Task.yield()
        XCTAssertTrue(window.performKeyEquivalent(with: try keyEvent(shortcut, window: window)))
        XCTAssertEqual(changes, [shortcut])
        await Task.yield()
        XCTAssertTrue(window.makeFirstResponder(host.recorder))
        await Task.yield()
        NSApp.sendEvent(try keyEvent(.init(.escape), window: window, characters: "\u{1b}"))
        await Task.yield()
        XCTAssertEqual(changes, [shortcut])
        XCTAssertEqual(host.recorder.shortcut, shortcut)
    }

    func testValidationDistinguishesFormatSystemAndAppConflicts() async {
        XCTAssertTrue(ShortcutValidation.rejectionReason(for: .init(.h, modifiers: .shift), current: nil,
            menus: [], takenBySystem: false)?.contains("Add Command") == true)
        XCTAssertTrue(ShortcutValidation.rejectionReason(for: .init(.h, modifiers: [.control, .shift]), current: nil,
            menus: [], takenBySystem: true)?.contains("System Settings") == true)
        XCTAssertNil(ShortcutValidation.rejectionReason(for: .init(.h, modifiers: [.command, .shift]), current: nil,
            menus: [], takenBySystem: false))
        XCTAssertNil(ShortcutValidation.rejectionReason(for: .init(.f18), current: nil,
            menus: [], takenBySystem: false))
        let shortcut = KeyboardShortcuts.Shortcut(.h, modifiers: [.command, .shift])
        let menu = NSMenu()
        let item = NSMenuItem(title: "Show Window", action: nil, keyEquivalent: "")
        item.setShortcut(shortcut)
        menu.addItem(item)
        XCTAssertNil(ShortcutValidation.rejectionReason(for: shortcut, current: shortcut,
            menus: [menu], takenBySystem: false))
    }

    func testSettingsSurfaceStaysOpaqueAtMinimumLyricOpacity() async throws {
        _ = NSApplication.shared
        let suite = "app.floatlyrics.settings-tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = AppModel(defaults: defaults, arguments: ["--demo"])
        model.opacity = 0.15
        let window = SettingsWindow(size: NSSize(width: 350, height: 540))
        defer { window.close() }
        let view = NSHostingView(rootView: PreferencesView(model: model, updates: UpdateChecker(),
            dismiss: {}, resize: { _ in }, initialPage: .behavior))
        window.contentView = view
        view.frame = NSRect(x: 0, y: 0, width: 350, height: 540)
        await Task.yield()
        view.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let center = try XCTUnwrap(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh - 10))
        XCTAssertGreaterThan(center.alphaComponent, 0.99)
        if let folder = ProcessInfo.processInfo.environment["FLOATLYRICS_SETTINGS_SNAPSHOT_DIR"] {
            try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            try png.write(to: URL(fileURLWithPath: folder).appendingPathComponent("settings-shortcuts.png"))
        }
    }

    private func keyEvent(_ shortcut: KeyboardShortcuts.Shortcut, window: NSWindow, characters: String = "H") throws -> NSEvent {
        try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: shortcut.modifiers,
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil,
            characters: characters, charactersIgnoringModifiers: characters.lowercased(), isARepeat: false,
            keyCode: UInt16(shortcut.carbonKeyCode)))
    }
}

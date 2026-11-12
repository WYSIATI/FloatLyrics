import AppKit
import KeyboardShortcuts
import XCTest
@testable import FloatLyrics

@MainActor
final class ShortcutRecorderTests: XCTestCase {
    func testRecorderRejectsShiftLetterThenRecordsSupportedCombination() async throws {
        _ = NSApplication.shared
        let window = RecorderTestPanel(contentRect: NSRect(x: 0, y: 0, width: 350, height: 180),
                                       styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.orderOut(nil); window.close() }
        var captured: KeyboardShortcuts.Shortcut?
        let recorder = KeyboardShortcuts.RecorderCocoa(shortcut: nil) { captured = $0 }
        recorder.conflictPolicy = .allowAll
        window.contentView?.addSubview(recorder)
        recorder.frame = NSRect(x: 20, y: 20, width: 150, height: 24)
        await Task.yield()
        XCTAssertTrue(window.makeFirstResponder(recorder))
        XCTAssertNotNil(recorder.currentEditor())
        await Task.yield()
        await Task.yield()

        try send(.init(.h, modifiers: [.shift]), characters: "H", to: window)
        XCTAssertNil(captured)
        XCTAssertNotNil(recorder.currentEditor())

        let shortcut = KeyboardShortcuts.Shortcut(.h, modifiers: [.control, .option])
        try send(shortcut, characters: "h", to: window)
        XCTAssertEqual(captured, shortcut)
    }

    private func send(_ shortcut: KeyboardShortcuts.Shortcut, characters: String, to window: NSWindow) throws {
        let event = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero,
            modifierFlags: shortcut.modifiers, timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil, characters: characters, charactersIgnoringModifiers: "h",
            isARepeat: false, keyCode: UInt16(shortcut.carbonKeyCode)))
        NSApp.sendEvent(event)
    }
}

private final class RecorderTestPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

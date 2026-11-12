import AppKit
import KeyboardShortcuts

/// Settings owns keyboard focus; lyric overlays remain non-activating panels.
final class SettingsWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(size: NSSize) {
        super.init(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .closable],
                   backing: .buffered, defer: false)
        isReleasedWhenClosed = false
        isOpaque = false // Only the rounded corners are transparent; the content is solid.
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        level = .floating
        title = "Float Lyrics Settings"
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let editor = firstResponder as? NSTextView,
           let recorder = editor.delegate as? KeyboardShortcuts.RecorderCocoa,
           let host = recorder.superview as? ShortcutRecorderHost,
           host.captureCommand(event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

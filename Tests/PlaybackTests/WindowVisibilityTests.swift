import AppKit
import KeyboardShortcuts
import XCTest
@testable import FloatLyrics

@MainActor
final class WindowVisibilityTests: XCTestCase {
    private func withDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "app.floatlyrics.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    func testHideAndShowFloatingWindowPreserveItsMode() async {
        withDefaults { defaults in
            let model = AppModel(defaults: defaults, arguments: [])
            XCTAssertEqual(model.visibilityMenuTitle, "Hide Window")
            model.hideLyrics()
            XCTAssertTrue(model.lyricsHidden)
            XCTAssertFalse(model.notchMode)
            XCTAssertEqual(model.visibilityMenuTitle, "Show Window")
            model.toggleLyricsVisibility()
            XCTAssertFalse(model.lyricsHidden)
            XCTAssertFalse(model.notchMode)
            XCTAssertEqual(model.visibilityMenuTitle, "Hide Window")
        }
    }

    func testShortcutTogglePreservesIslandMode() async {
        withDefaults { defaults in
            let model = AppModel(defaults: defaults, arguments: [])
            model.notchMode = true
            model.toggleLyricsVisibility()
            XCTAssertTrue(model.lyricsHidden)
            XCTAssertTrue(model.notchMode)
            XCTAssertEqual(model.visibilityMenuTitle, "Show Dynamic Island")
            model.toggleLyricsVisibility()
            XCTAssertFalse(model.lyricsHidden)
            XCTAssertTrue(model.notchMode)
            XCTAssertEqual(model.visibilityMenuTitle, "Hide Dynamic Island")
        }
    }

    func testExplicitModeChangeRevealsSelectedPresentation() async {
        withDefaults { defaults in
            let model = AppModel(defaults: defaults, arguments: [])
            model.hideLyrics()
            model.notchMode = true
            XCTAssertFalse(model.lyricsHidden)
            XCTAssertEqual(model.visibilityMenuTitle, "Hide Dynamic Island")
            model.hideLyrics()
            model.notchMode = false
            XCTAssertFalse(model.lyricsHidden)
            XCTAssertEqual(model.visibilityMenuTitle, "Hide Window")
        }
    }

    func testUnchangedModeDoesNotRevealHiddenLyrics() async {
        withDefaults { defaults in
            let model = AppModel(defaults: defaults, arguments: [])
            model.hideLyrics()
            model.notchMode = false
            XCTAssertTrue(model.lyricsHidden)
        }
    }

    func testRelaunchRestoresShortcutAndModeButStartsVisible() async {
        withDefaults { defaults in
            let shortcut = KeyboardShortcuts.Shortcut(.l, modifiers: [.control, .option, .command])
            let model = AppModel(defaults: defaults, arguments: [])
            XCTAssertNil(model.windowShortcut)
            model.windowShortcut = shortcut
            model.notchMode = true
            model.hideLyrics()

            let relaunched = AppModel(defaults: defaults, arguments: [])
            XCTAssertEqual(relaunched.windowShortcut, shortcut)
            XCTAssertTrue(relaunched.notchMode)
            XCTAssertFalse(relaunched.lyricsHidden)
        }
    }

    func testChangingAndClearingShortcutPersistImmediately() async {
        withDefaults { defaults in
            let model = AppModel(defaults: defaults, arguments: [])
            model.windowShortcut = .init(.l, modifiers: [.control, .option])
            let replacement = KeyboardShortcuts.Shortcut(.k, modifiers: [.command, .shift])
            model.windowShortcut = replacement
            XCTAssertEqual(AppModel(defaults: defaults, arguments: []).windowShortcut, replacement)
            model.windowShortcut = nil
            XCTAssertNil(AppModel(defaults: defaults, arguments: []).windowShortcut)
            XCTAssertNil(defaults.object(forKey: "windowShortcut.v1"))
        }
    }

    func testMalformedShortcutPreferenceLeavesItUnassigned() async {
        withDefaults { defaults in
            defaults.set(Data("{invalid".utf8), forKey: "windowShortcut.v1")
            XCTAssertNil(AppModel(defaults: defaults, arguments: []).windowShortcut)
        }
    }

    func testHideKeepsPlaybackAndPreferencesAvailable() async {
        withDefaults { defaults in
            let model = AppModel(defaults: defaults, arguments: ["--demo"])
            model.start()
            let track = model.snapshot.track
            let lyrics = model.lyrics
            model.hideLyrics()
            XCTAssertEqual(model.snapshot.track, track)
            XCTAssertEqual(model.lyrics, lyrics)
            XCTAssertTrue(model.snapshot.isPlaying)
            model.alwaysOnTop = false
            XCTAssertFalse(defaults.bool(forKey: "alwaysOnTop"))
        }
    }
}

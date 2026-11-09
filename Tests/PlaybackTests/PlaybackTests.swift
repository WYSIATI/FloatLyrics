import AppKit
import XCTest
import LyricsCore
@testable import FloatLyrics

final class PlaybackTests: XCTestCase {
    func testBothInstalledPlayerDictionariesAcceptSnapshotScripts() throws {
        for source in PlayerSource.allCases {
            guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: source.bundleID) != nil else { continue }
            let script = NSAppleScript(source: PlaybackBridge.script(for: source))!
            var error: NSDictionary?
            XCTAssertTrue(script.compileAndReturnError(&error), "\(source.name): \(String(describing: error))")
        }
    }
    func testPermissionErrorsAreRecognized() {
        XCTAssertTrue(PlaybackError(code: -1743, message: "Denied").permissionDenied)
        XCTAssertFalse(PlaybackError(code: -1712, message: "Timed out").permissionDenied)
    }
}

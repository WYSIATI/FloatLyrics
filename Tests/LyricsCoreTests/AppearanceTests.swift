import XCTest
@testable import LyricsCore

final class AppearanceTests: XCTestCase {
    func testAppearanceRoundTripKeepsIndependentProfiles() throws {
        var original = AppearancePreferences()
        original.palette = .midnight; original.windowInk = .custom; original.windowCustomHex = "ABCDEF"
        original.islandInk = .sky; original.islandOpacity = 0.45; original.islandWidth = 300
        let restored = AppearancePreferences.restore(try JSONEncoder().encode(original))
        XCTAssertEqual(restored, original)
        XCTAssertNotEqual(restored.windowColor, restored.islandColor)
    }
    func testOldAndInvalidPreferencesRecoverSafely() {
        let old = AppearancePreferences.restore(Data("{\"islandOpacity\":-2,\"islandWidth\":9999,\"windowCustomHex\":\"nope\",\"palette\":\"future\"}".utf8))
        XCTAssertEqual(old.islandOpacity, 0.15)
        XCTAssertEqual(old.islandWidth, 400)
        XCTAssertEqual(old.palette, .glacier)
        XCTAssertEqual(old.windowCustomHex, "345ECC")
        XCTAssertFalse(old.expandOnHover)
        XCTAssertEqual(AppearancePreferences.restore(Data("invalid".utf8)), AppearancePreferences())
    }
    func testAutomaticInkChangesWithSurfaceWhileIslandStaysLegible() {
        var appearance = AppearancePreferences()
        XCTAssertGreaterThan(appearance.windowColor.contrast(with: appearance.palette.surface), 10)
        appearance.palette = .midnight
        XCTAssertGreaterThan(appearance.windowColor.contrast(with: appearance.palette.surface), 10)
        XCTAssertGreaterThan(appearance.islandColor.contrast(with: RGBValue(hex: "000000")!), 10)
    }
    func testCustomColorValidationAndContrast() {
        XCTAssertEqual(RGBValue(hex: " #aBcDeF ")?.hex, "ABCDEF")
        XCTAssertNil(RGBValue(hex: "GG1122"))
        XCTAssertNil(RGBValue(hex: "123"))
        XCTAssertNil(RGBValue(hex: "123#456"))
        XCTAssertEqual(RGBValue(hex: "FFFFFF")!.contrast(with: RGBValue(hex: "000000")!), 21, accuracy: 0.001)
    }
}

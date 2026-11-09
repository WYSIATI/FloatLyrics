import XCTest
@testable import LyricsCore

final class AppearanceTests: XCTestCase {
    func testAppearanceRoundTripKeepsIndependentProfiles() throws {
        var original = AppearancePreferences()
        original.palette = .ink; original.windowInk = .custom; original.windowCustomHex = "B8B8B8"
        original.islandInk = .silver; original.islandOpacity = 0.45; original.islandWidth = 300
        let restored = AppearancePreferences.restore(try JSONEncoder().encode(original))
        XCTAssertEqual(restored, original)
        XCTAssertNotEqual(restored.windowColor, restored.islandColor)
    }
    func testOldAndInvalidPreferencesRecoverSafely() {
        let old = AppearancePreferences.restore(Data("{\"islandOpacity\":-2,\"islandWidth\":9999,\"windowCustomHex\":\"nope\",\"palette\":\"future\"}".utf8))
        XCTAssertEqual(old.islandOpacity, 0.15)
        XCTAssertEqual(old.islandWidth, 400)
        XCTAssertEqual(old.palette, .glass)
        XCTAssertEqual(old.windowCustomHex, "1F1F1F")
        XCTAssertFalse(old.expandOnHover)
        XCTAssertEqual(AppearancePreferences.restore(Data("invalid".utf8)), AppearancePreferences())
    }
    func testAutomaticInkChangesWithSurfaceWhileIslandStaysLegible() {
        var appearance = AppearancePreferences()
        XCTAssertGreaterThan(appearance.windowColor.contrast(with: appearance.palette.surface), 10)
        appearance.palette = .ink
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
    func testLegacyAccentPresetsBecomeNeutralWithoutLosingLayout() {
        let old = AppearancePreferences.restore(Data(#"{"palette":"lavender","windowInk":"blue","islandInk":"sky","islandOpacity":0.55,"islandWidth":310}"#.utf8))
        XCTAssertEqual(old.palette, .smoke)
        XCTAssertEqual(old.windowInk, .automatic)
        XCTAssertEqual(old.islandInk, .automatic)
        XCTAssertEqual(old.islandOpacity, 0.55)
        XCTAssertEqual(old.islandWidth, 310)
    }
    func testLegacyCoolCustomColorsAreMigratedButWarmChoicesAreKept() {
        let cool = AppearancePreferences.restore(Data(#"{"windowInk":"custom","windowCustomHex":"5C6FEA","islandInk":"custom","islandCustomHex":"C2D8FF"}"#.utf8))
        XCTAssertEqual(cool.windowInk, .automatic)
        XCTAssertEqual(cool.islandInk, .automatic)
        let warm = AppearancePreferences.restore(Data(#"{"windowInk":"custom","windowCustomHex":"8A4B35"}"#.utf8))
        XCTAssertEqual(warm.windowInk, .custom)
        XCTAssertEqual(warm.windowCustomHex, "8A4B35")
    }
    func testAllShippedMaterialsAndTextPresetsAreGrayscale() {
        for palette in SurfacePalette.allCases {
            for color in [palette.surface, palette.accent] {
                XCTAssertEqual(color.red, color.green)
                XCTAssertEqual(color.green, color.blue)
            }
        }
        for ink in LyricInk.allCases where ink != .custom {
            for dark in [false, true] {
                let color = ink.resolved(dark: dark, customHex: "")
                XCTAssertEqual(color.red, color.green)
                XCTAssertEqual(color.green, color.blue)
            }
        }
    }
}

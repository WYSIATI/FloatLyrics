import XCTest
@testable import FloatLyrics

final class NotchGeometryTests: XCTestCase {
    func testIslandStartsAtPhysicalScreenTopIncludingCamera() {
        let layout = NotchGeometry(screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982), safeTop: 32,
            leftArea: CGRect(x: 0, y: 950, width: 660, height: 32), rightArea: CGRect(x: 852, y: 950, width: 660, height: 32))
        XCTAssertEqual(layout.cameraWidth, 196)
        XCTAssertEqual(layout.cameraHeight, 32)
        XCTAssertEqual(layout.islandFrame(expanded: false).maxY, 982)
        XCTAssertEqual(layout.islandFrame(expanded: true).maxY, 982)
        XCTAssertEqual(layout.windowFrame.maxY, 982)
        XCTAssertGreaterThan(layout.compactSize.width, layout.cameraWidth)
        XCTAssertGreaterThan(layout.expandedSize.height, layout.compactSize.height)
    }
    func testExternalDisplayAndNegativeCoordinatesRemainTopCentered() {
        let layout = NotchGeometry(screenFrame: CGRect(x: -1920, y: 200, width: 1920, height: 1080), safeTop: 0, leftArea: nil, rightArea: nil)
        XCTAssertFalse(layout.hasCamera)
        XCTAssertEqual(layout.islandFrame(expanded: false).midX, -960)
        XCTAssertEqual(layout.windowFrame.maxY, 1280)
    }
    func testCompactIslandFitsCameraAndStaysWithinDisplay() {
        for displayWidth: CGFloat in [800, 1512, 1728] {
            for cameraWidth: CGFloat in [180, 240, 280] {
                for preference: CGFloat in [280, 320, 400] {
                    let side = (displayWidth - cameraWidth) / 2
                    let screen = CGRect(x: 0, y: 0, width: displayWidth, height: 982)
                    let layout = NotchGeometry(screenFrame: screen, safeTop: 32,
                        leftArea: CGRect(x: 0, y: 950, width: side, height: 32),
                        rightArea: CGRect(x: side + cameraWidth, y: 950, width: side, height: 32), preferredWidth: preference)
                    XCTAssertTrue(screen.contains(layout.islandFrame(expanded: false)))
                    XCTAssertTrue(screen.contains(layout.islandFrame(expanded: true)))
                    XCTAssertGreaterThanOrEqual(layout.compactSize.width - layout.cameraWidth, 60)
                    XCTAssertLessThanOrEqual(layout.compactSize.width, 400)
                    XCTAssertEqual(layout.compactSize.height, 56)
                }
            }
        }
    }
}

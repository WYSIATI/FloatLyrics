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
}

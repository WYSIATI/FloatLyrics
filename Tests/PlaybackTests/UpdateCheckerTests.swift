import XCTest
import LyricsCore
@testable import FloatLyrics

@MainActor
final class UpdateCheckerTests: XCTestCase {
    func testUserInitiatedCheckDisablesDuplicatesAndPresentsResult() async throws {
        let started = expectation(description: "Request started")
        let presented = expectation(description: "Result presented")
        let gate = UpdateRequestGate()
        let client = ReleaseUpdateClient(transport: { _ in
            started.fulfill()
            return await gate.wait()
        })
        var notices: [UpdateNotice] = []
        let checker = UpdateChecker(client: client, currentVersion: "1.5.0") { notice in
            notices.append(notice)
            presented.fulfill()
        }
        XCTAssertFalse(checker.isChecking)
        checker.checkForUpdates()
        checker.checkForUpdates()
        XCTAssertTrue(checker.isChecking)
        await fulfillment(of: [started], timeout: 2)
        await gate.finish()
        await fulfillment(of: [presented], timeout: 2)
        XCTAssertFalse(checker.isChecking)
        XCTAssertEqual(notices.count, 1)
        XCTAssertEqual(notices.first?.title, "You're up to date")
        XCTAssertNil(notices.first?.actionURL)
    }

    func testFailedCheckCanBeRetriedAndOffersOfficialReleases() async {
        let presented = expectation(description: "Failure presented twice")
        presented.expectedFulfillmentCount = 2
        let first = expectation(description: "First failure presented")
        var presentationCount = 0
        let checker = UpdateChecker(client: .init(transport: { _ in throw URLError(.notConnectedToInternet) }),
                                    currentVersion: "1.5.0") { notice in
            XCTAssertEqual(notice.title, "Couldn't check for updates")
            XCTAssertEqual(notice.actionURL, ReleaseUpdateClient.releasesURL)
            presentationCount += 1
            if presentationCount == 1 { first.fulfill() }
            presented.fulfill()
        }
        checker.checkForUpdates()
        await fulfillment(of: [first], timeout: 2)
        XCTAssertFalse(checker.isChecking)
        checker.checkForUpdates()
        await fulfillment(of: [presented], timeout: 2)
        XCTAssertFalse(checker.isChecking)
    }

    func testUpdateDialogDescribesManualInstallationAndShowsReleaseNotes() async throws {
        let client = ReleaseUpdateClient(transport: { _ in
            (Data(#"{"tag_name":"v1.6.0","draft":false,"prerelease":false,"assets":[{"name":"Float-Lyrics-1.6.0.dmg","state":"uploaded","size":100}]}"#.utf8), 200)
        })
        let notice = UpdateNotice.result(try await client.check(currentVersion: "1.5.0"), currentVersion: "1.5.0")
        XCTAssertEqual(notice.actionTitle, "Download Update…")
        XCTAssertEqual(notice.actionURL?.lastPathComponent, "Float-Lyrics-1.6.0.dmg")
        XCTAssertNotNil(notice.releaseURL)
        XCTAssertTrue(notice.message.contains("replace the app in Applications"))
    }

    func testNewerLocalBuildHasNoDowngradeAction() async throws {
        let notice = UpdateNotice.result(.newerThanPublicRelease(latest: try XCTUnwrap(AppVersion("1.4.2"))), currentVersion: "1.5.0")
        XCTAssertEqual(notice.title, "You're running a newer build")
        XCTAssertNil(notice.actionURL)
        XCTAssertTrue(notice.message.contains("1.4.2"))
    }
}

private actor UpdateRequestGate {
    private var continuation: CheckedContinuation<(Data, Int), Never>?
    private var finished = false
    private let response = (Data(#"{"tag_name":"v1.5.0","draft":false,"prerelease":false,"assets":[]}"#.utf8), 200)
    func wait() async -> (Data, Int) {
        if finished { return response }
        return await withCheckedContinuation { continuation = $0 }
    }
    func finish() {
        finished = true
        continuation?.resume(returning: response)
        continuation = nil
    }
}

import XCTest
@testable import LyricsCore

final class ReleaseUpdateTests: XCTestCase {
    func testVersionsCompareNumericallyAndRejectNonReleaseTags() throws {
        XCTAssertGreaterThan(try XCTUnwrap(AppVersion("1.10.0")), try XCTUnwrap(AppVersion("1.9.9")))
        XCTAssertGreaterThan(try XCTUnwrap(AppVersion("2.0.0")), try XCTUnwrap(AppVersion("1.99.99")))
        XCTAssertEqual(AppVersion("v1.5.0"), AppVersion("1.5.0"))
        for invalid in ["", "1.5", "1.5.0.1", "01.5.0", "1.5.0-beta.1", "1.5.0+dev", "1.5.-1", "1.٥.0", "v1.5.0/other", "1.5.0 "] {
            XCTAssertNil(AppVersion(invalid), invalid)
        }
    }

    func testAvailableReleasePrefersVersionedZIPAndUsesOnlyRepositoryURLs() async throws {
        let transport = UpdateTransportStub(data: try release(assets: [
            asset("Float-Lyrics-1.5.0.dmg"), asset("Float-Lyrics.dmg.zip"), asset("Float-Lyrics-1.5.0.dmg.zip")
        ]))
        let client = ReleaseUpdateClient(transport: { await transport.get($0) })
        guard case .available(let update) = try await client.check(currentVersion: "1.4.2") else {
            return XCTFail("Expected an update")
        }
        XCTAssertEqual(update.version.description, "1.5.0")
        XCTAssertEqual(update.downloadURL?.absoluteString, "https://github.com/WYSIATI/FloatLyrics/releases/download/v1.5.0/Float-Lyrics-1.5.0.dmg.zip")
        XCTAssertEqual(update.releaseURL.absoluteString, "https://github.com/WYSIATI/FloatLyrics/releases/tag/v1.5.0")
        let recordedRequest = await transport.request
        let request = try XCTUnwrap(recordedRequest)
        XCTAssertEqual(request.url?.absoluteString, "https://api.github.com/repos/WYSIATI/FloatLyrics/releases/latest")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-GitHub-Api-Version"), "2026-03-10")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(request.timeoutInterval, 15)
    }

    func testFallsBackToDMGWhenArchiveIsNotUploaded() async throws {
        let transport = UpdateTransportStub(data: try release(assets: [
            asset("Float-Lyrics-1.5.0.dmg.zip", state: "new"), asset("Float-Lyrics-1.5.0.dmg")
        ]))
        guard case .available(let update) = try await ReleaseUpdateClient(transport: { await transport.get($0) }).check(currentVersion: "1.4.2") else {
            return XCTFail("Expected an update")
        }
        XCTAssertEqual(update.downloadURL?.lastPathComponent, "Float-Lyrics-1.5.0.dmg")
    }

    func testMissingCompatibleInstallerOffersReleasePageWithoutFabricatedDownload() async throws {
        let transport = UpdateTransportStub(data: try release(assets: [
            asset("Float-Lyrics-1.5.0.dmg.zip", size: 0), asset("OtherApp.dmg"), asset("Float-Lyrics-1.4.2.dmg")
        ]))
        guard case .available(let update) = try await ReleaseUpdateClient(transport: { await transport.get($0) }).check(currentVersion: "1.4.2") else {
            return XCTFail("Expected an update")
        }
        XCTAssertNil(update.downloadURL)
        XCTAssertEqual(update.releaseURL.host, "github.com")
    }

    func testEqualVersionIsUpToDateAndNewerLocalVersionDoesNotDowngrade() async throws {
        let transport = UpdateTransportStub(data: try release())
        let client = ReleaseUpdateClient(transport: { await transport.get($0) })
        let equal = try await client.check(currentVersion: "1.5.0")
        let ahead = try await client.check(currentVersion: "1.6.0")
        XCTAssertEqual(equal, .upToDate)
        XCTAssertEqual(ahead, .newerThanPublicRelease(latest: try XCTUnwrap(AppVersion("1.5.0"))))
    }

    func testDraftPrereleaseAndInvalidTagsAreRejected() async throws {
        for data in [try release(draft: true), try release(prerelease: true), try release(tag: "v1.5.0-beta"), try release(tag: "../../other")] {
            let transport = UpdateTransportStub(data: data)
            do {
                _ = try await ReleaseUpdateClient(transport: { await transport.get($0) }).check(currentVersion: "1.4.2")
                XCTFail("Must reject unpublished or invalid releases")
            } catch UpdateCheckError.invalidResponse { }
        }
    }

    func testServiceFailuresHaveSpecificRecoveryMessages() async throws {
        for (status, expected) in [(403, UpdateCheckError.rateLimited), (429, .rateLimited), (404, .noPublicRelease), (503, .server(503))] {
            let transport = UpdateTransportStub(data: Data(), status: status)
            do {
                _ = try await ReleaseUpdateClient(transport: { await transport.get($0) }).check(currentVersion: "1.4.2")
                XCTFail("Must reject HTTP \(status)")
            } catch let error as UpdateCheckError { XCTAssertEqual(error, expected) }
        }
    }

    func testMalformedResponseAndUnknownInstalledVersionDoNotClaimUpToDate() async throws {
        let transport = UpdateTransportStub(data: Data("not JSON".utf8))
        let client = ReleaseUpdateClient(transport: { await transport.get($0) })
        do {
            _ = try await client.check(currentVersion: "")
            XCTFail("Must reject an unknown installed version")
        } catch UpdateCheckError.invalidCurrentVersion { }
        let count = await transport.count
        XCTAssertEqual(count, 0)
        do {
            _ = try await client.check(currentVersion: "1.4.2")
            XCTFail("Must reject malformed release data")
        } catch UpdateCheckError.invalidResponse { }
    }

    func testTransportFailureIsPropagated() async {
        let client = ReleaseUpdateClient(transport: { _ in throw URLError(.notConnectedToInternet) })
        do {
            _ = try await client.check(currentVersion: "1.4.2")
            XCTFail("Must report connection failure")
        } catch { XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet) }
    }

    private func release(tag: String = "v1.5.0", draft: Bool = false, prerelease: Bool = false,
                         assets: [[String: Any]] = []) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["tag_name": tag, "draft": draft, "prerelease": prerelease,
            "html_url": "https://untrusted.example/release", "assets": assets])
    }

    private func asset(_ name: String, state: String = "uploaded", size: Int = 100) -> [String: Any] {
        ["name": name, "state": state, "size": size, "browser_download_url": "https://untrusted.example/file"]
    }
}

private actor UpdateTransportStub {
    private let data: Data
    private let status: Int
    private(set) var request: URLRequest?
    private(set) var count = 0
    init(data: Data, status: Int = 200) { self.data = data; self.status = status }
    func get(_ request: URLRequest) -> (Data, Int) {
        self.request = request; count += 1
        return (data, status)
    }
}

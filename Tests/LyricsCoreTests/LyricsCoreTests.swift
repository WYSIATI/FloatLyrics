import XCTest
@testable import LyricsCore

final class LyricsCoreTests: XCTestCase {
    func testRepeatedTagsFractionsAndUnicode() {
        let lines = LRCParser.parse("[ar:Someone]\n[00:01.5][00:31.050]一起唱 ♪\n[00:02.123]Hello")
        XCTAssertEqual(lines.map(\.time), [1.5, 2.123, 31.05])
        XCTAssertEqual(lines[2].text, "一起唱 ♪")
    }
    func testOffsetAndBlankBreak() {
        let lines = LRCParser.parse("[offset:-500]\n[00:00.20]Start\n[00:04.00]\n[00:60.00]Invalid")
        XCTAssertEqual(lines, [.init(time: 0, text: "Start"), .init(time: 3.5, text: "")])
    }
    func testSeekAndBoundary() {
        let lyrics = Lyrics(lines: [.init(time: 2, text: "One"), .init(time: 5, text: "Two")], plainText: "")
        XCTAssertNil(lyrics.activeIndex(at: 0))
        XCTAssertEqual(lyrics.activeIndex(at: 5), 1)
        XCTAssertEqual(lyrics.activeIndex(at: 3), 0)
        XCTAssertEqual(lyrics.activeIndex(at: 4, adjustment: 1), 1)
        XCTAssertNil(lyrics.activeIndex(at: .nan))
    }
    func testPausedAndPlayingClock() {
        let date = Date(timeIntervalSince1970: 100)
        let track = Track(id: "1", title: "Title", artist: "Artist", album: "", duration: 20)
        XCTAssertEqual(PlaybackSnapshot(track: track, isPlaying: false, position: 4, sampledAt: date).position(at: date.addingTimeInterval(3)), 4)
        XCTAssertEqual(PlaybackSnapshot(track: track, isPlaying: true, position: 18, sampledAt: date).position(at: date.addingTimeInterval(3)), 20)
    }
    func testEnhancedLRC() {
        XCTAssertEqual(LRCParser.parse("[00:01.00]<00:01.00>Hello <00:01.50>world").first?.text, "Hello world")
    }
    func testFeaturedTagsKeepRecordingVersion() {
        XCTAssertEqual(LyricsRecord.lookupTitle("The Way (Remix) [feat. Emma Rae]"), "The Way (Remix)")
        XCTAssertEqual(LyricsRecord.lookupTitle("Song (Live)"), "Song (Live)")
        XCTAssertEqual(LyricsRecord.lookupTitle("Song (feat. Guest)"), "Song")
    }
    func testPlainLyricsAreNotInventedTimings() {
        let lyrics = Lyrics(lines: [], plainText: "One\nTwo")
        XCTAssertFalse(lyrics.isSynced)
        XCTAssertNil(lyrics.activeIndex(at: 120))
    }
    func testInstrumentalBreakAndEnd() {
        let lyrics = Lyrics(lines: [.init(time: 2, text: "One"), .init(time: 5, text: ""), .init(time: 9, text: "Two")], plainText: "")
        XCTAssertEqual(lyrics.lines[lyrics.activeIndex(at: 7)!].text, "")
        XCTAssertEqual(lyrics.activeIndex(at: 99), 2)
    }
    func testEmptySearchIsNotFound() async throws {
        let transport = MockTransport(responses: [(Data(), 404), (Data("[]".utf8), 200)])
        do { _ = try await LRCLibClient(transport: transport).fetch(Track(id: "1", title: "A", artist: "B", album: "", duration: 20)); XCTFail("Must throw") }
        catch { XCTAssertTrue(error.localizedDescription.contains("No lyrics")) }
    }
    func testMatchingRejectsWrongRecording() throws {
        let records = try JSONDecoder().decode([LyricsRecord].self, from: Data(Self.records.utf8))
        let track = Track(id: "1", title: "Café!", artist: "Artist", album: "Album", duration: 200)
        XCTAssertEqual(LyricsRecord.bestMatch(in: records, for: track)?.id, 2)
        XCTAssertNil(LyricsRecord.bestMatch(in: records, for: Track(id: "2", title: "Other song", artist: "Artist", album: "", duration: 200)))
    }
    func testNotFoundUsesSearchAndCache() async throws {
        let transport = MockTransport(responses: [(Data(), 404), (Data(Self.records.utf8), 200)])
        let client = LRCLibClient(transport: transport)
        let track = Track(id: "1", title: "Café", artist: "Artist", album: "Album", duration: 200)
        let lyrics = try await client.fetch(track)
        XCTAssertTrue(lyrics.isSynced)
        let cached = try await client.fetch(track)
        XCTAssertEqual(cached, lyrics)
        let count = await transport.count
        XCTAssertEqual(count, 2)
    }
    func testRateLimitDoesNotSearch() async throws {
        let transport = MockTransport(responses: [(Data(), 429)])
        do { _ = try await LRCLibClient(transport: transport).fetch(Track(id: "1", title: "A", artist: "B", album: "", duration: 2)); XCTFail("Must throw") }
        catch { XCTAssertTrue(error.localizedDescription.contains("busy")) }
        let count = await transport.count
        XCTAssertEqual(count, 1)
    }
    func testEmptyExactRecordFallsBackToUsableSearchResult() async throws {
        let empty = #"{"id":3,"trackName":"Cafe","artistName":"Artist","duration":200,"instrumental":false,"plainLyrics":"  ","syncedLyrics":"[00:00.00]"}"#
        let transport = MockTransport(responses: [(Data(empty.utf8), 200), (Data(Self.records.utf8), 200)])
        let result = try await LRCLibClient(transport: transport).fetch(Track(id: "1", title: "Cafe", artist: "Artist", album: "Album", duration: 200))
        XCTAssertEqual(result.recordID, 2)
        let count = await transport.count
        XCTAssertEqual(count, 2)
    }
    func testMalformedResponseHasReadableError() async throws {
        let transport = MockTransport(responses: [(Data("not json".utf8), 200)])
        do {
            _ = try await LRCLibClient(transport: transport).fetch(Track(id: "1", title: "A", artist: "B", album: "", duration: 20))
            XCTFail("Must reject malformed JSON")
        } catch LyricsError.invalidResponse { }
    }
    func testSearchRejectsWhitespaceOnlyLyrics() throws {
        let empty = #"[{"id":3,"trackName":"Cafe","artistName":"Artist","duration":200,"instrumental":false,"plainLyrics":" ","syncedLyrics":"[00:00.00]"}]"#
        let records = try JSONDecoder().decode([LyricsRecord].self, from: Data(empty.utf8))
        XCTAssertNil(LyricsRecord.bestMatch(in: records, for: Track(id: "1", title: "Cafe", artist: "Artist", album: "", duration: 200)))
    }
    private static let records = #"[{"id":1,"trackName":"Cafe","artistName":"Artist","albumName":"Live","duration":240,"instrumental":false,"plainLyrics":"Wrong","syncedLyrics":null},{"id":2,"trackName":"Cafe","artistName":"Artist","albumName":"Album","duration":200,"instrumental":false,"plainLyrics":"Hello","syncedLyrics":"[00:02.00]Hello"}]"#
}

private actor MockTransport: LyricsTransport {
    var count = 0
    let responses: [(Data, Int)]
    init(responses: [(Data, Int)]) { self.responses = responses }
    func get(_ request: URLRequest) async throws -> (Data, Int) {
        defer { count += 1 }
        return responses[min(count, responses.count - 1)]
    }
}

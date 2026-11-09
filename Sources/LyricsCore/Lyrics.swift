import Foundation

public struct LyricLine: Equatable, Codable, Sendable {
    public let time: Double
    public let text: String
    public init(time: Double, text: String) { self.time = time; self.text = text }
}

public struct Lyrics: Equatable, Codable, Sendable {
    public let lines: [LyricLine]
    public let plainText: String
    public let instrumental: Bool
    public let recordID: Int?
    public var isSynced: Bool { !lines.isEmpty }

    public init(lines: [LyricLine], plainText: String, instrumental: Bool = false, recordID: Int? = nil) {
        self.lines = lines; self.plainText = plainText; self.instrumental = instrumental; self.recordID = recordID
    }

    /// Last line at/before playback time. Blank lines deliberately preserve instrumental breaks.
    public func activeIndex(at position: Double, adjustment: Double = 0) -> Int? {
        guard position.isFinite, adjustment.isFinite else { return nil }
        let time = position + adjustment
        var low = 0, high = lines.count
        while low < high {
            let middle = (low + high) / 2
            if lines[middle].time <= time { low = middle + 1 } else { high = middle }
        }
        return low > 0 ? low - 1 : nil
    }
}

public enum LRCParser {
    public static func parse(_ text: String) -> [LyricLine] {
        let timestamp = try! NSRegularExpression(pattern: #"\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]"#)
        let offsetPattern = try! NSRegularExpression(pattern: #"\[offset:\s*([+-]?\d+)\]"#, options: .caseInsensitive)
        let fullRange = NSRange(text.startIndex..., in: text)
        var offset = 0.0
        if let match = offsetPattern.firstMatch(in: text, range: fullRange),
           let range = Range(match.range(at: 1), in: text) {
            offset = (Double(text[range]) ?? 0) / 1000
        }
        var result: [(Int, LyricLine)] = []
        for rawLine in text.components(separatedBy: .newlines) {
            let matches = timestamp.matches(in: rawLine, range: NSRange(rawLine.startIndex..., in: rawLine))
            guard let last = matches.last, let end = Range(last.range, in: rawLine)?.upperBound else { continue }
            let content = String(rawLine[end...]).trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: #"<\d{1,3}:\d{2}(?:\.\d{1,3})?>"#, with: "", options: .regularExpression)
            for match in matches {
                func part(_ n: Int) -> String { Range(match.range(at: n), in: rawLine).map { String(rawLine[$0]) } ?? "" }
                guard let minutes = Double(part(1)), let seconds = Double(part(2)), seconds < 60 else { continue }
                let fraction = part(3)
                let time = minutes * 60 + seconds + (Double("0." + fraction) ?? 0) + offset
                result.append((result.count, LyricLine(time: max(0, time), text: content)))
            }
        }
        return result.sorted { $0.1.time == $1.1.time ? $0.0 < $1.0 : $0.1.time < $1.1.time }.map(\.1)
    }
}

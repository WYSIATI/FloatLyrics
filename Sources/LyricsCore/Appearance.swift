import Foundation

public struct RGBValue: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public init?(hex: String) {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") { clean.removeFirst() }
        guard clean.count == 6, clean.allSatisfy({ $0.isHexDigit }), let value = UInt32(clean, radix: 16) else { return nil }
        red = Double((value >> 16) & 255) / 255
        green = Double((value >> 8) & 255) / 255
        blue = Double(value & 255) / 255
    }
    public var hex: String { String(format: "%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded())) }
    public var luminance: Double {
        func linear(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
    public func contrast(with other: Self) -> Double {
        (max(luminance, other.luminance) + 0.05) / (min(luminance, other.luminance) + 0.05)
    }
}

public enum SurfacePalette: String, CaseIterable, Codable, Sendable {
    case glacier, midnight, lavender
    public var name: String { switch self { case .glacier: "Glacier"; case .midnight: "Midnight"; case .lavender: "Lavender" } }
    public var isDark: Bool { self == .midnight }
    public var accent: RGBValue { RGBValue(hex: self == .glacier ? "557EF5" : self == .midnight ? "A2B7FF" : "9572DC")! }
    public var surface: RGBValue { RGBValue(hex: self == .glacier ? "EDF3FC" : self == .midnight ? "191E2B" : "F0ECF8")! }
}

public enum LyricInk: String, CaseIterable, Codable, Sendable {
    case automatic, graphite, white, blue, violet, sky, custom
    public var name: String {
        switch self { case .automatic: "Automatic"; case .graphite: "Graphite"; case .white: "White"; case .blue: "Blue"; case .violet: "Violet"; case .sky: "Ice"; case .custom: "Custom" }
    }
    public func resolved(dark: Bool, customHex: String) -> RGBValue {
        let hex: String
        switch self {
        case .automatic: hex = dark ? "F3F5FC" : "202637"
        case .graphite: hex = "202637"
        case .white: hex = "FFFFFF"
        case .blue: hex = "345ECC"
        case .violet: hex = "7650B7"
        case .sky: hex = "C2D8FF"
        case .custom: hex = customHex
        }
        return RGBValue(hex: hex) ?? LyricInk.automatic.resolved(dark: dark, customHex: "")
    }
}

public struct AppearancePreferences: Codable, Equatable, Sendable {
    public var palette: SurfacePalette = .glacier
    public var windowInk: LyricInk = .automatic
    public var islandInk: LyricInk = .automatic
    public var windowCustomHex = "345ECC"
    public var islandCustomHex = "C2D8FF"
    public var islandOpacity = 0.9
    public var islandWidth = 320.0
    public var expandOnHover = false
    public init() {}

    public var windowColor: RGBValue { windowInk.resolved(dark: palette.isDark, customHex: windowCustomHex) }
    public var islandColor: RGBValue { islandInk.resolved(dark: true, customHex: islandCustomHex) }

    private enum CodingKeys: String, CodingKey { case palette, windowInk, islandInk, windowCustomHex, islandCustomHex, islandOpacity, islandWidth, expandOnHover }
    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        palette = SurfacePalette(rawValue: (try? c.decode(String.self, forKey: .palette)) ?? "") ?? .glacier
        windowInk = LyricInk(rawValue: (try? c.decode(String.self, forKey: .windowInk)) ?? "") ?? .automatic
        islandInk = LyricInk(rawValue: (try? c.decode(String.self, forKey: .islandInk)) ?? "") ?? .automatic
        if let hex = try? c.decode(String.self, forKey: .windowCustomHex), let color = RGBValue(hex: hex) { windowCustomHex = color.hex }
        if let hex = try? c.decode(String.self, forKey: .islandCustomHex), let color = RGBValue(hex: hex) { islandCustomHex = color.hex }
        islandOpacity = min(1, max(0.15, (try? c.decode(Double.self, forKey: .islandOpacity)) ?? 0.9))
        islandWidth = min(400, max(280, (try? c.decode(Double.self, forKey: .islandWidth)) ?? 320))
        expandOnHover = (try? c.decode(Bool.self, forKey: .expandOnHover)) ?? false
    }

    public static func restore(_ data: Data?) -> Self {
        data.flatMap { try? JSONDecoder().decode(Self.self, from: $0) } ?? Self()
    }
}

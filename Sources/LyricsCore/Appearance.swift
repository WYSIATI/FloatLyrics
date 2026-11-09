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
    public var isBlueOrPurple: Bool {
        let high = max(red, green, blue), low = min(red, green, blue), delta = high - low
        guard delta > 0.08 else { return false }
        var hue: Double
        if high == red { hue = 60 * ((green - blue) / delta).truncatingRemainder(dividingBy: 6) }
        else if high == green { hue = 60 * ((blue - red) / delta + 2) }
        else { hue = 60 * ((red - green) / delta + 4) }
        if hue < 0 { hue += 360 }
        return (195...310).contains(hue)
    }
}

public enum SurfacePalette: String, CaseIterable, Codable, Sendable {
    case glass, smoke, ink
    public var name: String { switch self { case .glass: "Glass"; case .smoke: "Smoke"; case .ink: "Ink" } }
    public var isDark: Bool { self == .ink }
    public var accent: RGBValue { RGBValue(hex: isDark ? "E5E5E5" : "424242")! }
    public var surface: RGBValue { RGBValue(hex: self == .glass ? "F2F2F2" : self == .smoke ? "DADADA" : "1D1D1D")! }
}

public enum LyricInk: String, CaseIterable, Codable, Sendable {
    case automatic, graphite, charcoal, silver, white, custom
    public var name: String {
        switch self { case .automatic: "Automatic"; case .graphite: "Graphite"; case .charcoal: "Charcoal"; case .silver: "Silver"; case .white: "White"; case .custom: "Custom" }
    }
    public func resolved(dark: Bool, customHex: String) -> RGBValue {
        let hex: String
        switch self {
        case .automatic: hex = dark ? "F4F4F4" : "1F1F1F"
        case .graphite: hex = "1F1F1F"
        case .charcoal: hex = "4A4A4A"
        case .silver: hex = "C8C8C8"
        case .white: hex = "FFFFFF"
        case .custom: hex = customHex
        }
        return RGBValue(hex: hex) ?? LyricInk.automatic.resolved(dark: dark, customHex: "")
    }
}

public struct AppearancePreferences: Codable, Equatable, Sendable {
    public var palette: SurfacePalette = .glass
    public var windowInk: LyricInk = .automatic
    public var islandInk: LyricInk = .automatic
    public var windowCustomHex = "1F1F1F"
    public var islandCustomHex = "F4F4F4"
    public var islandOpacity = 0.9
    public var islandWidth = 320.0
    public var expandOnHover = false
    private var styleRevision = 2
    public init() {}

    public var windowColor: RGBValue { windowInk.resolved(dark: palette.isDark, customHex: windowCustomHex) }
    public var islandColor: RGBValue { islandInk.resolved(dark: true, customHex: islandCustomHex) }

    private enum CodingKeys: String, CodingKey { case palette, windowInk, islandInk, windowCustomHex, islandCustomHex, islandOpacity, islandWidth, expandOnHover, styleRevision }
    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let paletteName = (try? c.decode(String.self, forKey: .palette)) ?? ""
        palette = SurfacePalette(rawValue: paletteName) ?? (paletteName == "midnight" ? .ink : paletteName == "lavender" ? .smoke : .glass)
        windowInk = LyricInk(rawValue: (try? c.decode(String.self, forKey: .windowInk)) ?? "") ?? .automatic
        islandInk = LyricInk(rawValue: (try? c.decode(String.self, forKey: .islandInk)) ?? "") ?? .automatic
        if let hex = try? c.decode(String.self, forKey: .windowCustomHex), let color = RGBValue(hex: hex) { windowCustomHex = color.hex }
        if let hex = try? c.decode(String.self, forKey: .islandCustomHex), let color = RGBValue(hex: hex) { islandCustomHex = color.hex }
        if ((try? c.decode(Int.self, forKey: .styleRevision)) ?? 1) < 2 {
            // Replace the former app-supplied cool accents without resetting layout or opacity.
            if RGBValue(hex: windowCustomHex)?.isBlueOrPurple == true {
                windowCustomHex = "1F1F1F"
                if windowInk == .custom { windowInk = .automatic }
            }
            if RGBValue(hex: islandCustomHex)?.isBlueOrPurple == true {
                islandCustomHex = "F4F4F4"
                if islandInk == .custom { islandInk = .automatic }
            }
        }
        islandOpacity = min(1, max(0.15, (try? c.decode(Double.self, forKey: .islandOpacity)) ?? 0.9))
        islandWidth = min(400, max(280, (try? c.decode(Double.self, forKey: .islandWidth)) ?? 320))
        expandOnHover = (try? c.decode(Bool.self, forKey: .expandOnHover)) ?? false
    }

    public static func restore(_ data: Data?) -> Self {
        data.flatMap { try? JSONDecoder().decode(Self.self, from: $0) } ?? Self()
    }
}

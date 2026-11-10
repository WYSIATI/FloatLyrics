import AppKit
import SwiftUI
import LyricsCore

private enum AppearanceTarget: String, CaseIterable { case window = "Window", island = "Island" }
private enum SettingsPage {
    case root, music, appearance, details, behavior
    var title: String {
        switch self {
        case .root: "Settings"
        case .music: "Music player"
        case .appearance: "Appearance"
        case .details: "More options"
        case .behavior: "Behavior & timing"
        }
    }
    var height: CGFloat {
        switch self {
        case .root: 300
        case .music: 310
        case .appearance: 350
        case .details: 370
        case .behavior: 360
        }
    }
}

struct PreferencesView: View {
    static let size = CGSize(width: 350, height: SettingsPage.root.height)
    @ObservedObject var model: AppModel
    let dismiss: () -> Void
    let resize: (CGFloat) -> Void
    @State private var page: SettingsPage = .root
    @State private var target: AppearanceTarget
    @State private var hexDraft: String

    init(model: AppModel, dismiss: @escaping () -> Void, resize: @escaping (CGFloat) -> Void) {
        self.model = model
        self.dismiss = dismiss
        self.resize = resize
        _target = State(initialValue: model.notchMode ? .island : .window)
        _hexDraft = State(initialValue: model.notchMode ? model.appearance.islandCustomHex : model.appearance.windowCustomHex)
    }
    private var isIsland: Bool { target == .island }
    private var ink: Binding<LyricInk> { isIsland ? $model.appearance.islandInk : $model.appearance.windowInk }
    private var customHex: Binding<String> { isIsland ? $model.appearance.islandCustomHex : $model.appearance.windowCustomHex }
    private var opacity: Binding<Double> { isIsland ? $model.appearance.islandOpacity : $model.opacity }
    private var hexInput: Binding<String> {
        Binding(get: { hexDraft }, set: { value in
            hexDraft = value
            if let rgb = RGBValue(hex: value) { customHex.wrappedValue = rgb.hex; ink.wrappedValue = .custom }
        })
    }
    private var customColor: Binding<Color> {
        Binding(get: { (RGBValue(hex: customHex.wrappedValue) ?? model.appearance.windowColor).color }, set: { color in
            if let rgb = NSColor(color).usingColorSpace(.sRGB) {
                func byte(_ component: CGFloat) -> Int { Int((min(1, max(0, component)) * 255).rounded()) }
                customHex.wrappedValue = String(format: "%02X%02X%02X", byte(rgb.redComponent), byte(rgb.greenComponent), byte(rgb.blueComponent))
                hexDraft = customHex.wrappedValue
                ink.wrappedValue = .custom
            }
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 5) {
                if page != .root { IconButton(symbol: "chevron.left", label: "Back", action: goBack).keyboardShortcut(.cancelAction) }
                if page == .root {
                    BrandMark().fill(.primary).frame(width: 26, height: 26).padding(.trailing, 7).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Float Lyrics").font(.system(size: 14, weight: .semibold))
                        Text("Settings").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                } else {
                    Text(page == .details ? "\(target.rawValue) options" : page.title).font(.system(size: 14, weight: .medium))
                }
                Spacer()
                if page == .root {
                    IconButton(symbol: "xmark", label: "Close settings", action: dismiss).keyboardShortcut(.cancelAction)
                } else {
                    IconButton(symbol: "xmark", label: "Close settings", action: dismiss)
                }
            }
            pageContent
            Spacer(minLength: 0)
            if page == .root {
                HStack {
                    Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")")
                    Spacer()
                    Link("Help & source ↗", destination: URL(string: "https://github.com/WYSIATI/FloatLyrics#install")!)
                }.font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }.font(.system(size: 12)).padding(22).frame(width: Self.size.width, height: page.height)
            .modifier(GlassCardStyle(opacity: model.opacity, palette: model.appearance.palette))
            .onChange(of: page) { _, value in resize(value.height) }
            .onChange(of: target) { _, _ in hexDraft = customHex.wrappedValue }
    }

    @ViewBuilder private var pageContent: some View {
        switch page {
        case .root:
            VStack(spacing: 0) {
                navigationRow("Music player", symbol: "music.note", value: model.source.name) { page = .music }
                Divider().padding(.horizontal, 14)
                navigationRow("Appearance", symbol: "circle.lefthalf.filled") { page = .appearance }
                Divider().padding(.horizontal, 14)
                navigationRow("Behavior & timing", symbol: "slider.horizontal.3") { page = .behavior }
            }.background(.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 16))
        case .music:
            musicSettings
        case .appearance:
            appearanceSettings
        case .details:
            appearanceDetails
        case .behavior:
            behaviorSettings
        }
    }

    private var musicSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            GlassSegmentedControl(options: PlayerSource.allCases.map { ($0, $0.name) }, selection: $model.source,
                                  palette: model.appearance.palette, accessibilityPrefix: "Use ")
            Text(model.connectionMessage ?? (model.snapshot.track == nil ? "Play a song in \(model.source.name) to see its lyrics." : "Connected to \(model.source.name)."))
                .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button(model.denied ? "Open System Settings" : "Open \(model.source.name)") {
                    model.denied ? model.openAutomationSettings() : model.openPlayer()
                }
                Spacer()
                Button("Reconnect") { model.retry() }
            }.buttonStyle(.bordered).controlSize(.small)
            Divider()
            HStack {
                Link("Lyrics by LRCLIB", destination: URL(string: "https://lrclib.net")!)
                Spacer()
                Button("Refresh lyrics") { model.retry() }.buttonStyle(.plain).disabled(model.snapshot.track == nil)
            }.font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }

    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            GlassSegmentedControl(options: AppearanceTarget.allCases.map { ($0, $0.rawValue) }, selection: $target,
                                  palette: model.appearance.palette)
            VStack(alignment: .leading, spacing: 8) {
                HStack { sectionLabel("Background opacity"); Spacer(); Text(opacity.wrappedValue, format: .percent.precision(.fractionLength(0))).monospacedDigit().foregroundStyle(.secondary) }
                Slider(value: opacity, in: 0.15...1).accessibilityLabel(isIsland ? "Island opacity" : "Window opacity")
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack { sectionLabel("Lyric color"); Spacer(); Text(ink.wrappedValue.name).font(.system(size: 10)).foregroundStyle(.secondary) }
                HStack(spacing: 10) {
                    let options: [LyricInk] = isIsland ? [.automatic, .white, .silver, .charcoal] : [.automatic, .graphite, .charcoal, .silver]
                    ForEach(options, id: \.self) { color in swatch(color) }
                    Spacer()
                    if lowContrast {
                        Button("Use automatic") { ink.wrappedValue = .automatic }.font(.system(size: 10)).buttonStyle(.plain)
                    }
                }
            }
            navigationRow("More options") { page = .details }
                .background(.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var appearanceDetails: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Custom lyric color")
                HStack(spacing: 10) {
                    ColorPicker("Color", selection: customColor, supportsOpacity: false).labelsHidden()
                        .accessibilityLabel("Custom lyric color")
                    HStack(spacing: 3) {
                        Text("#").foregroundStyle(.tertiary)
                        TextField("RRGGBB", text: hexInput).textFieldStyle(.plain).font(.system(size: 11, design: .monospaced))
                            .accessibilityLabel("Custom color hex").onSubmit { hexDraft = customHex.wrappedValue }
                    }.padding(8).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                }
                if lowContrast { Text("Automatic gives this background better contrast.").font(.system(size: 10)).foregroundStyle(.secondary) }
            }
            if isIsland {
                VStack(alignment: .leading, spacing: 8) {
                    HStack { sectionLabel("Island width"); Spacer(); Text("\(Int(model.appearance.islandWidth)) pt").monospacedDigit().foregroundStyle(.secondary) }
                    Slider(value: $model.appearance.islandWidth, in: 280...400, step: 10).accessibilityLabel("Island width")
                }
                Toggle("Expand on hover", isOn: $model.appearance.expandOnHover).toggleStyle(.switch).controlSize(.small)
                Text("Click to expand. The island tucks away when you return to work.").font(.system(size: 10)).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Material")
                    GlassSegmentedControl(options: SurfacePalette.allCases.map { ($0, $0.name) }, selection: $model.appearance.palette,
                                          palette: model.appearance.palette, accessibilityPrefix: "Use material ")
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack { sectionLabel("Lyric size"); Spacer(); Text("\(Int(model.fontSize)) pt").foregroundStyle(.secondary) }
                    Slider(value: $model.fontSize, in: 18...34, step: 1).accessibilityLabel("Lyric size")
                }
            }
            Button("Reset \(target.rawValue.lowercased()) appearance") { resetTarget() }
                .font(.system(size: 10)).buttonStyle(.plain).foregroundStyle(.secondary)
        }
    }

    private var behaviorSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 14) {
                Toggle("Always on top", isOn: $model.alwaysOnTop)
                Toggle("Dynamic Island", isOn: $model.notchMode)
                Toggle("Click through lyrics", isOn: $model.clickThrough)
            }.toggleStyle(.switch).controlSize(.small)
            Text("Open Settings from the menu bar to turn click through off.").font(.system(size: 10)).foregroundStyle(.secondary)
            Divider()
            HStack {
                sectionLabel("Lyric timing")
                Spacer()
                Button { model.timingAdjustment = max(-5, model.timingAdjustment - 0.25) } label: { Image(systemName: "minus") }.accessibilityLabel("Show lyrics later")
                Text(String(format: "%+.2fs", model.timingAdjustment)).monospacedDigit().frame(width: 55)
                Button { model.timingAdjustment = min(5, model.timingAdjustment + 0.25) } label: { Image(systemName: "plus") }.accessibilityLabel("Show lyrics earlier")
            }.controlSize(.small)
            Text("+ shows lyrics earlier. Resets for each song.").font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }

    private func navigationRow(_ title: String, symbol: String? = nil, value: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary).frame(width: 18)
                }
                Text(title)
                Spacer()
                if let value { Text(value).font(.system(size: 11)).foregroundStyle(.secondary) }
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .medium)).foregroundStyle(.tertiary)
            }.padding(.horizontal, 14).frame(height: 51).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    private func sectionLabel(_ text: String) -> some View { Text(text).font(.system(size: 11, weight: .medium)) }
    private func goBack() { page = page == .details ? .appearance : .root }
    private func swatch(_ value: LyricInk) -> some View {
        Button { ink.wrappedValue = value } label: {
            ZStack {
                Circle().fill(value == .automatic ? Color.primary.opacity(0.04) : value.resolved(dark: isIsland || model.appearance.palette.isDark, customHex: customHex.wrappedValue).color)
                if value == .automatic { Text("A").font(.system(size: 12, weight: .medium)).foregroundStyle(.primary) }
            }.frame(width: 25, height: 25).padding(3)
                .overlay { Circle().strokeBorder(ink.wrappedValue == value ? model.accentColor : .primary.opacity(0.12), lineWidth: ink.wrappedValue == value ? 1.5 : 0.5) }
        }.buttonStyle(.plain).help(value.name).accessibilityLabel("\(value.name) lyric color").accessibilityAddTraits(ink.wrappedValue == value ? [.isSelected] : [])
    }
    private var lowContrast: Bool {
        let foreground = isIsland ? model.appearance.islandColor : model.appearance.windowColor
        let background = isIsland ? RGBValue(hex: "000000")! : model.appearance.palette.surface
        return foreground.contrast(with: background) < (isIsland ? 4.5 : 3)
    }
    private func resetTarget() {
        if isIsland {
            model.appearance.islandInk = .automatic; model.appearance.islandCustomHex = "F4F4F4"
            model.appearance.islandOpacity = 0.9; model.appearance.islandWidth = 320; model.appearance.expandOnHover = false
        } else {
            model.appearance.palette = .glass; model.appearance.windowInk = .automatic
            model.appearance.windowCustomHex = "1F1F1F"; model.opacity = 0.70; model.fontSize = 26
        }
        hexDraft = customHex.wrappedValue
    }
}

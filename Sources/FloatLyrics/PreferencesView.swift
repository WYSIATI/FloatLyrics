import AppKit
import SwiftUI
import LyricsCore

private enum AppearanceTarget: String, CaseIterable { case window = "Window", island = "Island" }

struct PreferencesView: View {
    static let size = CGSize(width: 366, height: 590)
    @ObservedObject var model: AppModel
    let dismiss: () -> Void
    @State private var target: AppearanceTarget
    @State private var hexDraft: String
    init(model: AppModel, dismiss: @escaping () -> Void) {
        self.model = model
        self.dismiss = dismiss
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                Text("Appearance").font(.system(size: 14, weight: .medium))
                Spacer()
                Button("Reset") { resetTarget() }.font(.system(size: 11)).buttonStyle(.plain).foregroundStyle(.secondary).help("Reset this view's appearance")
                IconButton(symbol: "xmark", label: "Close appearance", action: dismiss)
            }
            GlassSegmentedControl(options: AppearanceTarget.allCases.map { ($0, $0.rawValue) }, selection: $target,
                                  palette: model.appearance.palette)
            AppearancePreview(model: model, island: isIsland)
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { sectionLabel(isIsland ? "Lyric background" : "Glass opacity"); Spacer(); Text(opacity.wrappedValue, format: .percent.precision(.fractionLength(0))).monospacedDigit().foregroundStyle(.secondary) }
                        Slider(value: opacity, in: 0.15...1).accessibilityLabel(isIsland ? "Island opacity" : "Window opacity")
                        Text(isIsland ? "Only the lyric area fades. The camera cap stays seamless." : "Your lyrics stay crisp as the background fades.")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 9) {
                        sectionLabel("Lyric color")
                        HStack(spacing: 9) {
                            let options: [LyricInk] = isIsland ? [.automatic, .white, .silver, .charcoal] : [.automatic, .graphite, .charcoal, .silver]
                            ForEach(options, id: \.self) { color in swatch(color) }
                            Spacer(minLength: 0)
                        }
                        HStack {
                            Text(ink.wrappedValue.name).foregroundStyle(.secondary)
                            Spacer()
                            if lowContrast { Button("Use automatic") { ink.wrappedValue = .automatic }.buttonStyle(.plain).foregroundStyle(model.accentColor) }
                        }.font(.system(size: 10))
                        HStack(spacing: 10) {
                            ColorPicker("Custom", selection: customColor, supportsOpacity: false)
                                .help("Choose a custom lyric color").accessibilityLabel("Custom lyric color")
                            Spacer()
                            HStack(spacing: 3) {
                                Text("#").foregroundStyle(.tertiary)
                                TextField("RRGGBB", text: hexInput).textFieldStyle(.plain).font(.system(size: 11, design: .monospaced))
                                    .frame(width: 58).accessibilityLabel("Custom color hex")
                                    .onSubmit { hexDraft = customHex.wrappedValue }
                            }.padding(.horizontal, 8).padding(.vertical, 6).background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                        }.font(.system(size: 11))
                        if lowContrast { Text("This color may be hard to read. Automatic adapts to the background.").font(.system(size: 10)).foregroundStyle(.secondary) }
                    }
                    if !isIsland { palettePicker }
                    if isIsland {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { sectionLabel("Island width"); Spacer(); Text("\(Int(model.appearance.islandWidth)) pt").monospacedDigit().foregroundStyle(.secondary) }
                            Slider(value: $model.appearance.islandWidth, in: 280...400, step: 10).accessibilityLabel("Island width")
                            Toggle("Expand on hover", isOn: $model.appearance.expandOnHover).toggleStyle(.switch).controlSize(.small)
                            Text("Click to expand. It tucks away when you return to work.").font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { sectionLabel("Lyric size"); Spacer(); Text("\(Int(model.fontSize)) pt").foregroundStyle(.secondary) }
                            Slider(value: $model.fontSize, in: 18...34, step: 1).accessibilityLabel("Lyric size")
                        }
                    }
                    Divider()
                    VStack(spacing: 12) {
                        Toggle("Always on top", isOn: $model.alwaysOnTop)
                        Toggle("Dynamic Island", isOn: $model.notchMode)
                        Toggle("Click through lyrics", isOn: $model.clickThrough)
                    }.toggleStyle(.switch).controlSize(.small)
                    Text("Use the menu bar to restore interaction when click through is on.").font(.system(size: 10)).foregroundStyle(.secondary)
                    Divider()
                    HStack {
                        sectionLabel("Lyric timing")
                        Spacer()
                        Button { model.timingAdjustment = max(-5, model.timingAdjustment - 0.25) } label: { Image(systemName: "minus") }.accessibilityLabel("Show lyrics later")
                        Text(String(format: "%+.2fs", model.timingAdjustment)).monospacedDigit().frame(width: 55)
                        Button { model.timingAdjustment = min(5, model.timingAdjustment + 0.25) } label: { Image(systemName: "plus") }.accessibilityLabel("Show lyrics earlier")
                    }.controlSize(.small)
                    Text("+ shows lyrics earlier. Resets for each song.").font(.system(size: 10)).foregroundStyle(.secondary)
                    HStack {
                        Link("Lyrics by LRCLIB", destination: URL(string: "https://lrclib.net")!)
                        Spacer()
                        Button("Refresh lyrics") { model.retry() }.disabled(model.snapshot.track == nil)
                    }.font(.system(size: 10))
                }.padding(.vertical, 2).padding(.trailing, 4)
            }.frame(height: 315)
            Text("Changes apply immediately and are saved.").font(.system(size: 10)).foregroundStyle(.tertiary)
        }.font(.system(size: 12)).padding(22).frame(width: Self.size.width, height: Self.size.height)
            .modifier(GlassCardStyle(opacity: model.opacity, palette: model.appearance.palette))
            .onExitCommand(perform: dismiss)
            .onChange(of: target) { _, _ in hexDraft = customHex.wrappedValue }
    }
    private func sectionLabel(_ text: String) -> some View { Text(text).font(.system(size: 11, weight: .medium)) }
    private var palettePicker: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel("Material")
            HStack(spacing: 7) {
                ForEach(SurfacePalette.allCases, id: \.self) { palette in
                    Button { model.appearance.palette = palette } label: {
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 8).fill(palette.surface.color)
                                .overlay { LiquidAccent(palette: palette).padding(6) }.frame(height: 31)
                            Text(palette.name).font(.system(size: 9, weight: .medium)).foregroundStyle(.primary)
                        }.padding(5).frame(maxWidth: .infinity)
                            .background(model.appearance.palette == palette ? model.accentColor.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 11))
                            .overlay { RoundedRectangle(cornerRadius: 11).strokeBorder(model.appearance.palette == palette ? model.accentColor.opacity(0.5) : .primary.opacity(0.06), lineWidth: 1) }
                    }.buttonStyle(.plain).accessibilityLabel("\(palette.name) material").accessibilityAddTraits(model.appearance.palette == palette ? [.isSelected] : [])
                }
            }
        }
    }
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

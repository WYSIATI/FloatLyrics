import AppKit
import SwiftUI
import LyricsCore

/// The actual macOS glass compositor, rather than a tinted SwiftUI fill.
struct NativeGlass: NSViewRepresentable {
    var opacity: Double
    var radius: CGFloat = 30
    var palette: SurfacePalette = .glass
    func makeNSView(context: Context) -> NSView {
        let backdrop = NSVisualEffectView()
        backdrop.material = .hudWindow
        backdrop.blendingMode = .behindWindow
        backdrop.state = .active
        backdrop.appearance = NSAppearance(named: .vibrantLight)
        let surface = GlassBackdropView()
        surface.wantsLayer = true
        surface.layer?.cornerRadius = radius
        surface.layer?.masksToBounds = true
        surface.addSubview(backdrop)
        if #available(macOS 26, *) {
            let glass = NSGlassEffectView()
            glass.style = .clear
            glass.cornerRadius = radius
            glass.tintColor = NSColor.white.withAlphaComponent(0.12)
            glass.contentView = NSView()
            glass.appearance = NSAppearance(named: .aqua)
            surface.addSubview(glass)
        }
        return surface
    }
    func updateNSView(_ view: NSView, context: Context) {
        let alpha = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency ? 1 : opacity
        if view.alphaValue != alpha { view.alphaValue = alpha }
        for child in view.subviews {
            if let material = child as? NSVisualEffectView {
                let name: NSAppearance.Name = palette.isDark ? .vibrantDark : .vibrantLight
                if material.appearance?.name != name { material.appearance = NSAppearance(named: name) }
            }
            if #available(macOS 26, *), let glass = child as? NSGlassEffectView {
                let name: NSAppearance.Name = palette.isDark ? .darkAqua : .aqua
                if glass.appearance?.name != name { glass.appearance = NSAppearance(named: name) }
                let rgb = palette.surface
                let tint = NSColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 0.10)
                if glass.tintColor != tint { glass.tintColor = tint }
            }
        }
    }
}

private final class GlassBackdropView: NSView {
    override func layout() {
        super.layout()
        for view in subviews {
            if view.frame != bounds { view.frame = bounds }
            if #available(macOS 26, *), let glass = view as? NSGlassEffectView, glass.contentView?.frame != bounds { glass.contentView?.frame = bounds }
        }
    }
}

struct SurfaceRim: View {
    var radius: CGFloat = 30
    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(LinearGradient(stops: [
                .init(color: .white.opacity(0.45), location: 0),
                .init(color: .white.opacity(0.08), location: 0.35),
                .init(color: .black.opacity(0.04), location: 0.65),
                .init(color: .white.opacity(0.2), location: 1)
            ], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.65)
            .allowsHitTesting(false)
    }
}

/// Shared by the lyric window and Appearance, including material, edge and control tint.
struct GlassCardStyle: ViewModifier {
    var opacity: Double
    var palette: SurfacePalette
    func body(content: Content) -> some View {
        content
            .background { NativeGlass(opacity: opacity, palette: palette) }
            .overlay { SurfaceRim() }
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .environment(\.colorScheme, palette.isDark ? .dark : .light)
            .tint(palette.accent.color)
    }
}

struct GlassSegmentedControl<Selection: Hashable>: View {
    let options: [(Selection, String)]
    @Binding var selection: Selection
    var palette: SurfacePalette
    var accessibilityPrefix = ""
    @Namespace private var highlight
    @State private var hovered: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        HStack(spacing: 1) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button { selection = option.0 } label: {
                    Text(option.1).font(.system(size: 11, weight: selection == option.0 ? .medium : .regular))
                        .foregroundStyle(.primary.opacity(selection == option.0 ? 0.9 : 0.5))
                        .lineLimit(1).frame(maxWidth: .infinity).frame(height: 29)
                        .background {
                            if selection == option.0 {
                                LiquidAccent(palette: palette, energized: hovered == index).matchedGeometryEffect(id: "selection", in: highlight)
                            }
                        }.contentShape(Capsule())
                }.buttonStyle(.plain).onHover { hovered = $0 ? index : nil }
                    .accessibilityLabel(accessibilityPrefix + option.1)
                    .accessibilityAddTraits(selection == option.0 ? [.isSelected] : [])
            }
        }.padding(3).background(.primary.opacity(0.035), in: Capsule())
            .overlay { Capsule().strokeBorder(.primary.opacity(0.06), lineWidth: 0.65).allowsHitTesting(false) }
            .animation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.85), value: selection)
    }
}

struct IconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void
    @State private var hovered = false
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 11, weight: .medium))
                .frame(width: 28, height: 28)
                .background { if hovered { Circle().fill(.primary.opacity(0.06)) } }
                .contentShape(Circle())
        }.buttonStyle(.plain).foregroundStyle(.primary.opacity(hovered ? 0.9 : 0.5))
            .onHover { hovered = $0 }.animation(.easeOut(duration: 0.16), value: hovered)
            .help(label).accessibilityLabel(label)
    }
}

import AppKit
import SwiftUI
import LyricsCore

/// The actual macOS glass compositor, rather than a tinted SwiftUI fill.
struct NativeGlass: NSViewRepresentable {
    var opacity: Double
    var radius: CGFloat = 30
    var palette: SurfacePalette = .glacier
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

struct PlaybackPulse: View {
    var active: Bool
    var color: Color = .primary
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.2, paused: !active || reduceMotion)) { context in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<4) { index in
                    Capsule().fill(color.opacity(0.7)).frame(width: 2, height: active ? 5 + 9 * abs(sin(context.date.timeIntervalSince1970 * 2.8 + Double(index))) : 4)
                }
            }.frame(width: 18, height: 18)
        }.accessibilityLabel(active ? "Playing" : "Paused")
    }
}

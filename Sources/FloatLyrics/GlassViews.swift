import AppKit
import SwiftUI

/// The actual macOS glass compositor, rather than a tinted SwiftUI fill.
struct NativeGlass: NSViewRepresentable {
    var opacity: Double
    var radius: CGFloat = 30
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
        view.alphaValue = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency ? 1 : opacity
    }
}

private final class GlassBackdropView: NSView {
    override func layout() {
        super.layout()
        for view in subviews {
            view.frame = bounds
            if #available(macOS 26, *), let glass = view as? NSGlassEffectView { glass.contentView?.frame = bounds }
        }
    }
}

struct SilverRim: View {
    var radius: CGFloat = 30
    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(LinearGradient(stops: [
                .init(color: .white.opacity(0.95), location: 0),
                .init(color: .white.opacity(0.2), location: 0.35),
                .init(color: .black.opacity(0.10), location: 0.65),
                .init(color: .white.opacity(0.65), location: 1)
            ], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            .allowsHitTesting(false)
    }
}

struct SilverSelection: View {
    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [.white.opacity(0.9), Color(white: 0.93).opacity(0.55), .white.opacity(0.75)], startPoint: .top, endPoint: .bottom))
            .overlay {
                Capsule().strokeBorder(AngularGradient(colors: [
                    .white, Color(white: 0.62).opacity(0.6), .white,
                    Color(red: 0.74, green: 0.75, blue: 0.82).opacity(0.7), .white,
                    Color(white: 0.50).opacity(0.4), .white
                ], center: .center, angle: .degrees(35)), lineWidth: 1.6)
            }
            .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
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
                .background { if hovered { SilverSelection() } }
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

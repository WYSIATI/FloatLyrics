import SwiftUI

struct GlassSurface: ViewModifier {
    var radius: CGFloat = 28
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: radius))
        } else if #available(macOS 26, *) {
            content.glassEffect(.regular.tint(.black.opacity(0.12)), in: .rect(cornerRadius: radius))
        } else {
            content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(.white.opacity(0.18)))
        }
    }
}

struct IconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 12, weight: .medium)).frame(width: 28, height: 28).contentShape(Circle()) }
            .buttonStyle(.plain).foregroundStyle(.secondary)
            .help(label).accessibilityLabel(label)
    }
}

struct PlaybackPulse: View {
    var active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.3, paused: !active || reduceMotion)) { context in
            HStack(alignment: .center, spacing: 2.5) {
                ForEach(0..<4) { index in
                    Capsule().fill(Color.mint.opacity(0.9)).frame(width: 3, height: active ? 7 + 12 * abs(sin(context.date.timeIntervalSince1970 * 2.8 + Double(index))) : 5)
                }
            }.frame(width: 22, height: 22)
        }.accessibilityLabel(active ? "Playing" : "Paused")
    }
}

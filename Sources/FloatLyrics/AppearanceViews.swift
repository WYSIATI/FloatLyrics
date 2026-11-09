import AppKit
import SwiftUI
import LyricsCore

extension RGBValue {
    var color: Color { Color(red: red, green: green, blue: blue) }
}

extension AppModel {
    var lyricColor: Color { appearance.windowColor.color }
    var islandLyricColor: Color { appearance.islandColor.color }
    var accentColor: Color { appearance.palette.accent.color }
}

/// Broad, flowing reflections rather than an embossed chrome border. Motion is hover-only.
struct LiquidAccent: View {
    var palette: SurfacePalette = .glacier
    var energized = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !energized || reduceMotion)) { timeline in
            let phase = energized && !reduceMotion ? timeline.date.timeIntervalSinceReferenceDate * 0.5 : 0.0
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                context.fill(Path(roundedRect: rect, cornerRadius: size.height / 2), with: .color(palette.isDark ? .white.opacity(0.09) : .white.opacity(0.6)))
                var light = context
                light.addFilter(.blur(radius: size.height * 0.42))
                for i in 0..<3 {
                    let x = size.width * (0.15 + Double(i) * 0.38 + 0.12 * sin(phase + Double(i) * 1.7))
                    let y = size.height * (0.5 + 0.5 * sin(phase * 0.7 + Double(i) * 2))
                    let blob = CGRect(x: x - size.width * 0.3, y: y - size.height, width: size.width * 0.6, height: size.height * 2)
                    light.fill(Path(ellipseIn: blob), with: .radialGradient(Gradient(colors: [palette.accent.color.opacity(i == 1 ? 0.22 : 0.10), .clear]), center: CGPoint(x: x, y: y), startRadius: 0, endRadius: size.width * 0.34))
                }
                var ribbon = Path()
                ribbon.move(to: CGPoint(x: -10, y: size.height * 0.8))
                ribbon.addCurve(to: CGPoint(x: size.width + 10, y: size.height * 0.18), control1: CGPoint(x: size.width * 0.28, y: -size.height * (0.5 + 0.15 * sin(phase))), control2: CGPoint(x: size.width * 0.65, y: size.height * 1.25))
                context.stroke(ribbon, with: .linearGradient(Gradient(colors: [.clear, .white.opacity(0.75), palette.accent.color.opacity(0.16), .clear]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)), lineWidth: 0.75)
            }
        }.clipShape(Capsule())
            .overlay { Capsule().strokeBorder(.white.opacity(palette.isDark ? 0.12 : 0.65), lineWidth: 0.65) }
    }
}

struct AppearancePreview: View {
    @ObservedObject var model: AppModel
    var island: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.035))
            HStack(spacing: 5) {
                ForEach(0..<18) { i in Rectangle().fill(Color.primary.opacity(i % 3 == 0 ? 0.075 : 0.025)).frame(width: 7) }
            }.padding(.vertical, 12).mask(RoundedRectangle(cornerRadius: 16))
            if island {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4).fill(.black).frame(width: 95, height: 10)
                    Text("Keep a melody beside you")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(model.islandLyricColor)
                        .frame(width: min(280, model.appearance.islandWidth * 0.72), height: 30)
                        .background(.black.opacity(model.appearance.islandOpacity), in: UnevenRoundedRectangle(bottomLeadingRadius: 10, bottomTrailingRadius: 10))
                }
            } else {
                Text("Keep a melody beside you").font(.system(size: 17, weight: .medium))
                    .foregroundStyle(model.lyricColor).frame(maxWidth: .infinity).padding(.vertical, 20)
                    .background(model.appearance.palette.surface.color.opacity(model.opacity), in: RoundedRectangle(cornerRadius: 16))
                    .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.5), lineWidth: 0.7) }
                    .padding(.horizontal, 16)
            }
        }.frame(height: 88).accessibilityLabel("Live appearance preview")
    }
}

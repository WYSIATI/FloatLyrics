import SwiftUI

struct NotchView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var presentation: IslandPresentation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var expanded: Bool { presentation.expanded }
    private var geometry: NotchGeometry { presentation.geometry }
    private var size: CGSize { expanded ? geometry.expandedSize : geometry.compactSize }

    var body: some View {
        VStack(spacing: 0) {
            cameraRow
            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                VStack(spacing: expanded ? 10 : 0) {
                    if expanded {
                        Text(model.snapshot.track.map { "\($0.title) · \($0.artist)" } ?? model.source.name)
                            .font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.45)).lineLimit(1)
                    }
                    Text(model.line(at: context.date))
                        .font(.system(size: expanded ? 23 : 15, weight: .medium))
                        .foregroundStyle(.white).multilineTextAlignment(.center)
                        .lineLimit(expanded ? 2 : 1).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: expanded ? 52 : 24)
                        .contentTransition(.opacity)
                    if expanded {
                        Text(nextLine(at: context.date)).font(.system(size: 13)).foregroundStyle(.white.opacity(0.35)).lineLimit(1)
                        HStack(spacing: 5) {
                            Text(model.source.name); Text("·"); Text(model.snapshot.isPlaying ? "Live lyrics" : "Paused")
                        }.font(.system(size: 10)).foregroundStyle(.white.opacity(0.35)).padding(.top, 3)
                    }
                }.padding(.horizontal, expanded ? 38 : 25)
            }
            Spacer(minLength: 0)
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(.black, in: IslandSilhouette(shoulder: expanded ? 18 : 7, bottom: expanded ? 30 : 18))
        .clipShape(IslandSilhouette(shoulder: expanded ? 18 : 7, bottom: expanded ? 30 : 18))
        .shadow(color: .black.opacity(expanded ? 0.3 : 0), radius: 12, y: 8)
        .contentShape(IslandSilhouette(shoulder: expanded ? 18 : 7, bottom: expanded ? 30 : 18))
        .onTapGesture { presentation.open() }
        .animation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.82), value: expanded)
        .frame(width: geometry.windowFrame.width, height: geometry.windowFrame.height, alignment: .top)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    private var cameraRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "music.note").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.8))
                if expanded { Text("FloatLyrics").font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.5)) }
            }.frame(maxWidth: .infinity)
            // This exact center area sits behind the physical camera housing.
            Color.clear.frame(width: geometry.cameraWidth, height: geometry.cameraHeight)
            HStack(spacing: 12) {
                if expanded {
                    Button { model.notchMode = false } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 10, weight: .medium))
                    }.buttonStyle(.plain).help("Return to floating window").accessibilityLabel("Return to floating window")
                    Button { presentation.close() } label: { Image(systemName: "chevron.up").font(.system(size: 10, weight: .medium)) }
                        .buttonStyle(.plain).help("Collapse island").accessibilityLabel("Collapse island")
                } else {
                    PlaybackPulse(active: model.snapshot.isPlaying)
                        .accessibilityValue("\(Int(model.snapshot.position)) seconds")
                }
            }.foregroundStyle(.white.opacity(0.65)).frame(maxWidth: .infinity)
        }.padding(.horizontal, 20).frame(height: geometry.cameraHeight)
    }
    private func nextLine(at date: Date) -> String {
        guard let lyrics = model.lyrics, let index = lyrics.activeIndex(at: model.snapshot.position(at: date), adjustment: model.timingAdjustment), lyrics.lines.indices.contains(index + 1) else { return " " }
        return lyrics.lines[index + 1].text
    }
}

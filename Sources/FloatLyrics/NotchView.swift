import SwiftUI

struct NotchView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var presentation: IslandPresentation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var expanded: Bool { presentation.expanded }
    private var geometry: NotchGeometry { presentation.geometry }
    private var size: CGSize { expanded ? geometry.expandedSize : geometry.compactSize }
    private var silhouette: IslandSilhouette { IslandSilhouette(shoulder: expanded ? 12 : 5, bottom: expanded ? 22 : 12) }

    var body: some View {
        VStack(spacing: 0) {
            cameraRow
            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                VStack(spacing: expanded ? 6 : 0) {
                    if expanded {
                        Text(model.snapshot.track.map { "\($0.title) · \($0.artist)" } ?? model.source.name)
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.5)).lineLimit(1).padding(.top, 5)
                    }
                    Text(model.line(at: context.date))
                        .font(.system(size: expanded ? 20 : 13, weight: .medium))
                        .foregroundStyle(model.islandLyricColor).multilineTextAlignment(.center)
                        .lineLimit(expanded ? 2 : 1).minimumScaleFactor(0.9)
                        .frame(maxWidth: .infinity, minHeight: expanded ? 44 : 22)
                        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                        .contentTransition(.opacity)
                        .help(model.line(at: context.date))
                    if expanded {
                        recoveryOrStatus
                    }
                }.padding(.horizontal, expanded ? 26 : 18)
            }
            Spacer(minLength: 0)
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .background {
            silhouette.fill(.black.opacity(model.appearance.islandOpacity))
            // Keep the physical camera cap fully black; only the lyric extension fades.
            Rectangle().fill(.black).frame(height: geometry.cameraHeight).frame(maxHeight: .infinity, alignment: .top)
        }
        .clipShape(silhouette)
        .contentShape(silhouette)
        .onTapGesture { presentation.pin() }
        .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.9), value: expanded)
        .frame(width: geometry.windowFrame.width, height: geometry.windowFrame.height, alignment: .top)
        .ignoresSafeArea().preferredColorScheme(.dark)
    }
    @ViewBuilder private var recoveryOrStatus: some View {
        if model.denied {
            Button("Connect \(model.source.name)") { model.openAutomationSettings() }
                .buttonStyle(.plain).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.85))
        } else if model.lyricsMessage != nil {
            Button("Retry lyrics") { model.retry() }
                .buttonStyle(.plain).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.85))
        } else if model.snapshot.track == nil {
            Button("Open \(model.source.name)") { model.openPlayer() }
                .buttonStyle(.plain).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.85))
        } else {
            HStack(spacing: 4) { Text(model.source.name); Text("·"); Text(model.snapshot.isPlaying ? "Live lyrics" : "Paused") }
                .font(.system(size: 9)).foregroundStyle(.white.opacity(0.4))
        }
    }
    private var cameraRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "music.note").font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.65))
                if expanded { Text("Lyrics").font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.45)) }
            }.frame(maxWidth: .infinity)
            Color.clear.frame(width: geometry.cameraWidth, height: geometry.cameraHeight)
            HStack(spacing: 12) {
                if expanded {
                    Button { model.notchMode = false } label: { Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 10, weight: .medium)) }
                        .buttonStyle(.plain).help("Return to floating window").accessibilityLabel("Return to floating window")
                    Button { presentation.close() } label: { Image(systemName: "chevron.up").font(.system(size: 10, weight: .medium)) }
                        .buttonStyle(.plain).help("Collapse island").accessibilityLabel("Collapse island")
                } else {
                    Circle().fill(model.islandLyricColor.opacity(model.snapshot.isPlaying ? 0.7 : 0.3)).frame(width: 3, height: 3)
                        .accessibilityLabel(model.snapshot.isPlaying ? "Playing" : "Paused")
                }
            }.foregroundStyle(.white.opacity(0.6)).frame(maxWidth: .infinity)
        }.padding(.horizontal, expanded ? 16 : 12).frame(height: geometry.cameraHeight)
    }
}

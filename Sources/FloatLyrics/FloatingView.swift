import SwiftUI
import LyricsCore

struct FloatingView: View {
    static let size = CGSize(width: 400, height: 224)
    @ObservedObject var model: AppModel
    let hide: () -> Void
    let showPreferences: () -> Void
    let quit: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var optionsHovered = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.snapshot.track?.title ?? "Float Lyrics").font(.system(size: 12, weight: .medium)).lineLimit(1)
                    Text(model.snapshot.track?.artist ?? model.source.name).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
                optionsMenu
            }.foregroundStyle(.secondary).padding(.horizontal, 24).padding(.top, 19)

            lyricContent.frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer().frame(height: 18)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .modifier(GlassCardStyle(opacity: model.opacity, palette: model.appearance.palette))
    }

    private var optionsMenu: some View {
        Menu {
            Menu("Music Player") {
                Picker("Music Player", selection: $model.source) {
                    ForEach(PlayerSource.allCases, id: \.self) { Text($0.name).tag($0) }
                }.pickerStyle(.inline)
            }
            Button("Move to Dynamic Island") { model.notchMode = true }
            Button("Settings…", action: showPreferences)
            Divider()
            Button("Hide Window", action: hide)
            Divider()
            Button("Quit Float Lyrics", action: quit)
                .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "ellipsis").font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary).frame(width: 28, height: 28)
                .background(.primary.opacity(optionsHovered ? 0.06 : 0), in: Circle()).contentShape(Circle())
        }.menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .onHover { optionsHovered = $0 }
            .help("Lyrics options").accessibilityLabel("Lyrics options")
    }

    @ViewBuilder private var lyricContent: some View {
        if model.snapshot.track == nil {
            VStack(spacing: 9) {
                BrandMark().fill(model.lyricColor.opacity(0.55)).frame(width: 21, height: 21).accessibilityHidden(true)
                Text(model.denied ? "Connect your music" : "Play something you love.").font(.system(size: 20, weight: .medium))
                Text(model.connectionMessage ?? "Play a song in \(model.source.name). The words will follow.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button(model.denied ? "Open Settings" : "Open \(model.source.name)") { model.denied ? model.openAutomationSettings() : model.openPlayer() }
                    if model.denied { Button("Try again") { model.retry() } }
                }.buttonStyle(.bordered).controlSize(.small).padding(.top, 2)
            }.padding(.horizontal, 36)
        } else if model.loading {
            HStack(spacing: 10) { ProgressView().controlSize(.mini); Text("Finding the words…").font(.system(size: 16)).foregroundStyle(.secondary) }
        } else if let message = model.lyricsMessage {
            VStack(spacing: 10) {
                Text("Lyrics unavailable").font(.system(size: 21, weight: .medium))
                Text(message).font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Try again") { model.retry() }.buttonStyle(.bordered).controlSize(.small)
            }.padding(28)
        } else if let lyrics = model.lyrics, !lyrics.isSynced, !lyrics.instrumental {
            VStack(spacing: 7) {
                Text("UNSYNCED LYRICS").font(.system(size: 8, weight: .medium)).tracking(1.4).foregroundStyle(.secondary)
                ScrollView { Text(lyrics.plainText).font(.system(size: 18, weight: .medium)).foregroundStyle(model.lyricColor).lineSpacing(8).multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.vertical, 8) }
            }.padding(.horizontal, 28).padding(.vertical, 12)
        } else {
            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                let index = model.lyrics?.activeIndex(at: model.snapshot.position(at: context.date), adjustment: model.timingAdjustment)
                let current = model.line(at: context.date)
                VStack(spacing: 14) {
                    Text(current).font(.system(size: model.fontSize, weight: .medium))
                        .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.65)
                        .foregroundStyle(model.lyricColor).frame(maxWidth: .infinity, minHeight: 58)
                        .contentTransition(.opacity)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: current)
                    Text(nextLine(index: index)).font(.system(size: 12)).foregroundStyle(model.lyricColor.opacity(0.46)).lineLimit(1)
                }.padding(.horizontal, 30)
            }
        }
    }
    private func nextLine(index: Int?) -> String {
        guard let lyrics = model.lyrics, lyrics.isSynced else { return " " }
        let target = index.map { $0 + 1 } ?? 0
        return lyrics.lines.indices.contains(target) ? lyrics.lines[target].text : " "
    }
}

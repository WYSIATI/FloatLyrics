import SwiftUI
import LyricsCore

struct FloatingView: View {
    @ObservedObject var model: AppModel
    let hide: () -> Void
    @State private var settings = false
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "waveform").foregroundStyle(.mint)
                Text("FloatLyrics").font(.system(size: 12, weight: .semibold, design: .rounded))
                Spacer()
                IconButton(symbol: "macbook", label: "Move to notch") { model.notchMode = true }
                IconButton(symbol: "slider.horizontal.3", label: "Appearance and timing") { settings.toggle() }
                    .popover(isPresented: $settings, arrowEdge: .bottom) { PreferencesView(model: model).padding(22).frame(width: 310) }
                IconButton(symbol: "xmark", label: "Hide lyrics (reopen from menu bar)", action: hide)
            }.padding(.horizontal, 20).padding(.top, 15)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.07))
                    Image(systemName: model.source == .spotify ? "waveform" : "music.note")
                        .font(.system(size: 22, weight: .medium)).foregroundStyle(.mint)
                }.frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.snapshot.track?.title ?? "Ready when you are")
                        .font(.system(size: 15, weight: .semibold)).lineLimit(1)
                    Text(model.snapshot.track?.artist ?? "A little music for your working day")
                        .font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
                PlaybackPulse(active: model.snapshot.isPlaying)
                    .accessibilityValue("\(Int(model.snapshot.position)) seconds")
            }.padding(.horizontal, 24).padding(.top, 19)

            lyricContent.frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 8) {
                Circle().fill(model.snapshot.isPlaying ? .mint : .secondary.opacity(0.5)).frame(width: 5, height: 5)
                Menu {
                    Picker("Music source", selection: $model.source) {
                        ForEach(PlayerSource.allCases) { source in Text(source.name).tag(source) }
                    }
                    Button("Open \(model.source.name)") { model.openPlayer() }
                } label: {
                    HStack(spacing: 5) { Text(model.source.name); Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold)) }
                }.menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().help("Choose your music app")
                if model.demo { Text("PREVIEW").font(.system(size: 9, weight: .bold)).foregroundStyle(.mint) }
                Spacer()
                if model.snapshot.track != nil {
                    Text(model.loading ? "Finding lyrics" : model.lyrics?.isSynced == true ? "LIVE LYRICS" : model.lyrics?.instrumental == true ? "INSTRUMENTAL" : "LRCLIB")
                        .font(.system(size: 9, weight: .semibold, design: .rounded)).tracking(1.2).foregroundStyle(.secondary)
                    if !model.snapshot.isPlaying { Image(systemName: "pause.fill").font(.system(size: 9)).foregroundStyle(.secondary).help("Playback paused") }
                } else { Text("MADE FOR THE MOMENT").font(.system(size: 8, weight: .medium)).tracking(1).foregroundStyle(.tertiary) }
            }.font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 24).padding(.bottom, 20)
        }
        .frame(width: 460, height: 342)
        .modifier(GlassSurface())
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder private var lyricContent: some View {
        if let message = model.connectionMessage, model.snapshot.track == nil {
            VStack(spacing: 15) {
                Image(systemName: model.denied ? "lock.open" : "headphones").font(.system(size: 26, weight: .light)).foregroundStyle(.mint.opacity(0.8))
                Text(model.denied ? "One small permission" : "Press play. Find your voice.").font(.system(size: 21, weight: .medium, design: .rounded))
                Text(message).font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button(model.denied ? "Open Settings" : "Open \(model.source.name)") { model.denied ? model.openAutomationSettings() : model.openPlayer() }
                    if model.denied { Button("Try again") { model.retry() } }
                }.buttonStyle(.bordered).controlSize(.small)
            }.padding(.horizontal, 36)
        } else if model.loading {
            VStack(spacing: 12) { ProgressView().controlSize(.small); Text("Finding the words…").font(.system(size: 17, design: .rounded)).foregroundStyle(.secondary) }
        } else if let message = model.lyricsMessage {
            VStack(spacing: 12) {
                Text("Some songs keep their words.").font(.system(size: 20, weight: .medium, design: .rounded))
                Text(message).font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Retry lyrics") { model.retry() }.buttonStyle(.bordered).controlSize(.small)
            }.padding(30)
        } else if let lyrics = model.lyrics, !lyrics.isSynced, !lyrics.instrumental {
            VStack(spacing: 7) {
                Text("UNSYNCED LYRICS").font(.system(size: 9, weight: .semibold)).tracking(1.5).foregroundStyle(.mint)
                ScrollView { Text(lyrics.plainText).font(.system(size: 18, weight: .medium, design: .rounded)).lineSpacing(9).multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.vertical, 8) }
            }.padding(.horizontal, 28).padding(.vertical, 12)
        } else {
            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                let lyrics = model.lyrics
                let index = lyrics?.activeIndex(at: model.snapshot.position(at: context.date), adjustment: model.timingAdjustment)
                VStack(spacing: 14) {
                    Text(adjacentLine(index: index, delta: -1)).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.32)).lineLimit(1)
                    Text(model.line(at: context.date))
                        .font(.system(size: model.fontSize, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.65)
                        .foregroundStyle(.white).shadow(color: .black.opacity(0.18), radius: 5, y: 2)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .contentTransition(.opacity)
                    Text(adjacentLine(index: index, delta: 1)).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.40)).lineLimit(1)
                }.padding(.horizontal, 30)
            }
        }
    }

    private func adjacentLine(index: Int?, delta: Int) -> String {
        guard let lyrics = model.lyrics, lyrics.isSynced else { return " " }
        let target = index.map { $0 + delta } ?? (delta > 0 ? 0 : -1)
        return lyrics.lines.indices.contains(target) ? lyrics.lines[target].text : " "
    }
}

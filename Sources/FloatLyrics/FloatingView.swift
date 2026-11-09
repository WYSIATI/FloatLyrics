import SwiftUI
import LyricsCore

struct FloatingView: View {
    static let size = CGSize(width: 440, height: 304)
    @ObservedObject var model: AppModel
    let hide: () -> Void
    @State private var settings = false
    @Namespace private var selection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening").font(.system(size: 11, weight: .semibold))
                Text("FloatLyrics").font(.system(size: 11, weight: .medium)).tracking(0.2)
                Spacer()
                IconButton(symbol: "macbook", label: "Move to Dynamic Island") { model.notchMode = true }
                IconButton(symbol: "slider.horizontal.3", label: "Appearance and timing") { settings.toggle() }
                    .popover(isPresented: $settings, arrowEdge: .bottom) { PreferencesView(model: model).padding(24).frame(width: 320).preferredColorScheme(.light) }
                IconButton(symbol: "xmark", label: "Hide lyrics (reopen from menu bar)", action: hide)
            }.foregroundStyle(.secondary).padding(.horizontal, 18).padding(.top, 12)

            HStack(spacing: 11) {
                ZStack {
                    SilverSelection()
                    Image(systemName: "music.note").font(.system(size: 16, weight: .medium)).foregroundStyle(.primary.opacity(0.7))
                }.frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.snapshot.track?.title ?? "Nothing playing yet").font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    Text(model.snapshot.track?.artist ?? "Choose a player below").font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 4)
                PlaybackPulse(active: model.snapshot.isPlaying).accessibilityValue("\(Int(model.snapshot.position)) seconds")
            }.padding(.horizontal, 27).padding(.top, 14)

            lyricContent.frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 12) {
                sourcePicker
                Spacer(minLength: 0)
                Text(model.demo ? "PREVIEW" : model.loading ? "FINDING LYRICS" : model.lyrics?.isSynced == true ? "SYNCED" : "LRCLIB")
                    .font(.system(size: 8, weight: .medium)).tracking(1.3).foregroundStyle(.secondary)
            }.padding(.horizontal, 24).padding(.bottom, 19)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background { NativeGlass(opacity: model.opacity) }
        .overlay { SilverRim() }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .environment(\.colorScheme, .light)
        .tint(.primary)
    }

    private var sourcePicker: some View {
        HStack(spacing: 1) {
            ForEach(PlayerSource.allCases) { source in
                Button { model.source = source } label: {
                    Text(source.name).font(.system(size: 10, weight: model.source == source ? .semibold : .regular))
                        .foregroundStyle(.primary.opacity(model.source == source ? 0.85 : 0.45))
                        .frame(width: source == .spotify ? 77 : 96, height: 28)
                        .background {
                            if model.source == source { SilverSelection().matchedGeometryEffect(id: "player", in: selection) }
                        }.contentShape(Capsule())
                }.buttonStyle(.plain).accessibilityLabel("Use \(source.name)")
                    .accessibilityAddTraits(model.source == source ? [.isSelected] : [])
            }
        }.padding(3)
            .background(.white.opacity(0.18), in: Capsule())
            .overlay { Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 0.7).allowsHitTesting(false) }
            .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.76), value: model.source)
    }

    @ViewBuilder private var lyricContent: some View {
        if let message = model.connectionMessage, model.snapshot.track == nil {
            VStack(spacing: 10) {
                Text(model.denied ? "Connect your music" : "Play something you love.").font(.system(size: 21, weight: .medium))
                Text(message).font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
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
                ScrollView { Text(lyrics.plainText).font(.system(size: 18, weight: .medium)).lineSpacing(8).multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.vertical, 8) }
            }.padding(.horizontal, 28).padding(.vertical, 12)
        } else {
            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                let index = model.lyrics?.activeIndex(at: model.snapshot.position(at: context.date), adjustment: model.timingAdjustment)
                let current = model.line(at: context.date)
                VStack(spacing: 12) {
                    Text(adjacentLine(index: index, delta: -1)).font(.system(size: 13)).foregroundStyle(.primary.opacity(0.28)).lineLimit(1)
                    Text(current).font(.system(size: model.fontSize, weight: .medium))
                        .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.65)
                        .foregroundStyle(.primary.opacity(0.9)).frame(maxWidth: .infinity, minHeight: 58)
                        .contentTransition(.opacity)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: current)
                    Text(adjacentLine(index: index, delta: 1)).font(.system(size: 13)).foregroundStyle(.primary.opacity(0.4)).lineLimit(1)
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

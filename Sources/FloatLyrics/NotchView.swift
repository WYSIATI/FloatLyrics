import SwiftUI

struct NotchView: View {
    @ObservedObject var model: AppModel
    let topInset: CGFloat
    @State private var hovered = false
    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)
            HStack(spacing: 15) {
                PlaybackPulse(active: model.snapshot.isPlaying)
                TimelineView(.periodic(from: .now, by: 0.1)) { context in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.snapshot.track.map { "\($0.title) · \($0.artist)" } ?? model.source.name)
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.48)).lineLimit(1)
                        Text(model.line(at: context.date))
                            .font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                            .lineLimit(2).minimumScaleFactor(0.75).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Button { model.notchMode = false } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(hovered ? 0.8 : 0.3)).frame(width: 28, height: 32)
                }.buttonStyle(.plain).help("Expand floating lyrics").accessibilityLabel("Expand floating lyrics")
            }.padding(.horizontal, 25).frame(height: 84)
                .background(.black.opacity(0.95), in: UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24))
                .overlay(alignment: .bottom) { UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24).strokeBorder(.white.opacity(0.08)).allowsHitTesting(false) }
        }.frame(width: 510).onHover { hovered = $0 }
            .preferredColorScheme(.dark)
    }
}

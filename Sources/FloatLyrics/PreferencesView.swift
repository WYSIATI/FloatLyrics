import SwiftUI

struct PreferencesView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Make room for your music").font(.system(size: 16, weight: .semibold, design: .rounded))
            VStack(alignment: .leading, spacing: 7) {
                HStack { Text("Opacity"); Spacer(); Text(model.opacity, format: .percent.precision(.fractionLength(0))).monospacedDigit().foregroundStyle(.secondary) }
                Slider(value: $model.opacity, in: 0.25...1).accessibilityLabel("Window opacity")
                Text("A softer window leaves your work in view.").font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 7) {
                HStack { Text("Lyric size"); Spacer(); Text("\(Int(model.fontSize)) pt").foregroundStyle(.secondary) }
                Slider(value: $model.fontSize, in: 18...34, step: 1).accessibilityLabel("Lyric size")
            }
            Toggle("Always on top", isOn: $model.alwaysOnTop)
            Toggle("Notch mode", isOn: $model.notchMode)
            Toggle("Click through lyrics", isOn: $model.clickThrough)
            Text("When click through is on, use the menu bar to change settings or restore interaction.").font(.caption).foregroundStyle(.secondary)
            Divider()
            HStack {
                Text("Timing")
                Spacer()
                Button { model.timingAdjustment = max(-5, model.timingAdjustment - 0.25) } label: { Image(systemName: "minus") }.accessibilityLabel("Show lyrics later")
                Text(String(format: "%+.2fs", model.timingAdjustment)).monospacedDigit().frame(width: 57)
                Button { model.timingAdjustment = min(5, model.timingAdjustment + 0.25) } label: { Image(systemName: "plus") }.accessibilityLabel("Show lyrics earlier")
            }.controlSize(.small)
            Text("+ shows lyrics earlier. Resets for each song.").font(.caption).foregroundStyle(.secondary)
            HStack {
                Link("Lyrics by LRCLIB", destination: URL(string: "https://lrclib.net")!)
                Spacer()
                Button("Refresh lyrics") { model.retry() }.disabled(model.snapshot.track == nil)
            }.font(.caption)
        }.font(.system(size: 12)).tint(.mint)
    }
}

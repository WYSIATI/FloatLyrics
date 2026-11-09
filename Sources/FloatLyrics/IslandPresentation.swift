import AppKit
import SwiftUI

@MainActor
final class IslandPresentation: ObservableObject {
    @Published var expanded = false
    @Published var geometry: NotchGeometry
    private var tracking: Timer?
    private var collapse: Task<Void, Never>?
    private weak var panel: NSPanel?
    private weak var app: AppModel?
    private var pinned = false
    private var requiresPointerExit = false

    init(geometry: NotchGeometry) { self.geometry = geometry }
    func track(panel: NSPanel, app: AppModel) {
        self.panel = panel; self.app = app
        // Reading pointer location needs no event tap or Accessibility permission.
        tracking = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updatePointer() }
        }
        RunLoop.main.add(tracking!, forMode: .common)
    }
    func open() { collapse?.cancel(); collapse = nil; expanded = true }
    func pin() { pinned = true; requiresPointerExit = false; open() }
    func close() { collapse?.cancel(); collapse = nil; pinned = false; requiresPointerExit = true; expanded = false }
    private func updatePointer() {
        guard let panel, panel.isVisible, let app, app.notchMode else { return }
        let frame = geometry.islandFrame(expanded: expanded)
        let point = NSEvent.mouseLocation
        let local = CGPoint(x: point.x - frame.minX, y: frame.maxY - point.y)
        let inside = IslandSilhouette(shoulder: expanded ? 12 : 5, bottom: expanded ? 22 : 12)
            .path(in: CGRect(origin: .zero, size: frame.size)).contains(local)
        panel.ignoresMouseEvents = app.clickThrough || !inside
        guard !app.clickThrough else { close(); return }
        if !inside { requiresPointerExit = false }
        if inside { collapse?.cancel(); collapse = nil }
        if inside, !requiresPointerExit, app.appearance.expandOnHover { open() }
        else if !inside, expanded, collapse == nil {
            let delay = pinned ? 2500 : 450
            collapse = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(delay))
                guard !Task.isCancelled else { return }
                self?.expanded = false; self?.pinned = false; self?.collapse = nil
            }
        }
    }
}

/// Concave shoulders join the display edge, with a continuous rounded lower edge.
struct IslandSilhouette: Shape {
    var shoulder: CGFloat
    var bottom: CGFloat
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(shoulder, bottom) }
        set { shoulder = newValue.first; bottom = newValue.second }
    }
    func path(in rect: CGRect) -> Path {
        let s = min(shoulder, rect.height / 3), b = min(bottom, rect.height / 2)
        return Path { p in
            p.move(to: .zero)
            p.addCurve(to: CGPoint(x: s, y: s), control1: CGPoint(x: s * 0.8, y: 0), control2: CGPoint(x: s, y: s * 0.2))
            p.addLine(to: CGPoint(x: s, y: rect.height - b))
            p.addCurve(to: CGPoint(x: s + b, y: rect.height), control1: CGPoint(x: s, y: rect.height - b * 0.35), control2: CGPoint(x: s + b * 0.35, y: rect.height))
            p.addLine(to: CGPoint(x: rect.width - s - b, y: rect.height))
            p.addCurve(to: CGPoint(x: rect.width - s, y: rect.height - b), control1: CGPoint(x: rect.width - s - b * 0.35, y: rect.height), control2: CGPoint(x: rect.width - s, y: rect.height - b * 0.35))
            p.addLine(to: CGPoint(x: rect.width - s, y: s))
            p.addCurve(to: CGPoint(x: rect.width, y: 0), control1: CGPoint(x: rect.width - s, y: s * 0.2), control2: CGPoint(x: rect.width - s * 0.8, y: 0))
            p.closeSubpath()
        }
    }
}

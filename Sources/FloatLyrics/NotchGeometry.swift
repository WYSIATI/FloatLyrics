import AppKit

/// Display points, anchored at the physical display edge including the camera region.
struct NotchGeometry: Equatable {
    let screenFrame: CGRect
    let cameraWidth: CGFloat
    let cameraHeight: CGFloat
    let hasCamera: Bool
    let preferredWidth: CGFloat

    init(screenFrame: CGRect, safeTop: CGFloat, leftArea: CGRect?, rightArea: CGRect?, preferredWidth: CGFloat = 320) {
        self.screenFrame = screenFrame
        self.preferredWidth = min(400, max(280, preferredWidth))
        hasCamera = safeTop > 0
        cameraHeight = hasCamera ? safeTop : 30
        if hasCamera, let leftArea, let rightArea, leftArea.width > 0, rightArea.width > 0 {
            cameraWidth = max(100, screenFrame.width - leftArea.width - rightArea.width + 4)
        } else { cameraWidth = hasCamera ? 184 : 160 }
    }
    @MainActor init(screen: NSScreen, preferredWidth: CGFloat = 320) {
        self.init(screenFrame: screen.frame, safeTop: screen.safeAreaInsets.top,
                  leftArea: screen.auxiliaryTopLeftArea, rightArea: screen.auxiliaryTopRightArea, preferredWidth: preferredWidth)
    }
    var compactSize: CGSize { CGSize(width: min(screenFrame.width - 32, max(preferredWidth, cameraWidth + 60)), height: cameraHeight + 24) }
    var expandedSize: CGSize { CGSize(width: min(screenFrame.width - 32, max(440, cameraWidth + 150)), height: cameraHeight + 104) }
    var windowFrame: CGRect {
        CGRect(x: screenFrame.midX - (expandedSize.width + 20) / 2,
               y: screenFrame.maxY - expandedSize.height - 10,
               width: expandedSize.width + 20, height: expandedSize.height + 10)
    }
    func islandFrame(expanded: Bool) -> CGRect {
        let size = expanded ? expandedSize : compactSize
        return CGRect(x: screenFrame.midX - size.width / 2, y: screenFrame.maxY - size.height, width: size.width, height: size.height)
    }
}

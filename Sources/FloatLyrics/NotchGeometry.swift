import AppKit

/// Display points, anchored at the physical display edge including the camera region.
struct NotchGeometry: Equatable {
    let screenFrame: CGRect
    let cameraWidth: CGFloat
    let cameraHeight: CGFloat
    let hasCamera: Bool

    init(screenFrame: CGRect, safeTop: CGFloat, leftArea: CGRect?, rightArea: CGRect?) {
        self.screenFrame = screenFrame
        hasCamera = safeTop > 0
        cameraHeight = hasCamera ? safeTop : 30
        if hasCamera, let leftArea, let rightArea, leftArea.width > 0, rightArea.width > 0 {
            cameraWidth = max(100, screenFrame.width - leftArea.width - rightArea.width + 4)
        } else { cameraWidth = hasCamera ? 184 : 160 }
    }
    @MainActor init(screen: NSScreen) {
        self.init(screenFrame: screen.frame, safeTop: screen.safeAreaInsets.top,
                  leftArea: screen.auxiliaryTopLeftArea, rightArea: screen.auxiliaryTopRightArea)
    }
    var compactSize: CGSize { CGSize(width: min(screenFrame.width - 32, max(420, cameraWidth + 110)), height: cameraHeight + 32) }
    var expandedSize: CGSize { CGSize(width: min(screenFrame.width - 32, max(540, cameraWidth + 200)), height: cameraHeight + 156) }
    var windowFrame: CGRect {
        CGRect(x: screenFrame.midX - (expandedSize.width + 40) / 2,
               y: screenFrame.maxY - expandedSize.height - 20,
               width: expandedSize.width + 40, height: expandedSize.height + 20)
    }
    func islandFrame(expanded: Bool) -> CGRect {
        let size = expanded ? expandedSize : compactSize
        return CGRect(x: screenFrame.midX - size.width / 2, y: screenFrame.maxY - size.height, width: size.width, height: size.height)
    }
}

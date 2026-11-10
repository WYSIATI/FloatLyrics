import AppKit
import SwiftUI

/// An F with a lifted first line. Keep the geometry in sync with docs/brand/mark.svg.
struct BrandMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: CGRect(x: 8, y: 0, width: 92, height: 20), cornerRadius: 10)
        path.move(to: CGPoint(x: 10, y: 36))
        path.addLine(to: CGPoint(x: 66, y: 36))
        path.addQuadCurve(to: CGPoint(x: 76, y: 46), control: CGPoint(x: 76, y: 36))
        path.addQuadCurve(to: CGPoint(x: 66, y: 56), control: CGPoint(x: 76, y: 56))
        path.addLine(to: CGPoint(x: 20, y: 56))
        path.addLine(to: CGPoint(x: 20, y: 90))
        path.addQuadCurve(to: CGPoint(x: 10, y: 100), control: CGPoint(x: 20, y: 100))
        path.addQuadCurve(to: CGPoint(x: 0, y: 90), control: CGPoint(x: 0, y: 100))
        path.addLine(to: CGPoint(x: 0, y: 46))
        path.addQuadCurve(to: CGPoint(x: 10, y: 36), control: CGPoint(x: 0, y: 36))
        path.closeSubpath()
        let side = min(rect.width, rect.height)
        return path.applying(CGAffineTransform(scaleX: side / 100, y: side / 100))
            .offsetBy(dx: rect.midX - side / 2, dy: rect.midY - side / 2)
    }

    @MainActor static var menuBarImage: NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: true) { rect in
            NSColor.black.setFill()
            let context = NSGraphicsContext.current!.cgContext
            context.addPath(BrandMark().path(in: rect.insetBy(dx: 1, dy: 1)).cgPath)
            context.fillPath()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Float Lyrics"
        return image
    }
}

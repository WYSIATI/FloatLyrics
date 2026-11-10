import AppKit

// Vector artwork, drawn at each output size so the menu/Dock icon stays crisp.
// The same lifted-line F appears in BrandMark.swift and docs/brand/mark.svg.
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = output.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func markPath() -> NSBezierPath {
    let path = NSBezierPath(roundedRect: NSRect(x: 8, y: 0, width: 92, height: 20), xRadius: 10, yRadius: 10)
    // Quadratic curves expressed as cubics, matching the canonical SVG.
    path.move(to: NSPoint(x: 10, y: 36))
    path.line(to: NSPoint(x: 66, y: 36))
    path.curve(to: NSPoint(x: 76, y: 46), controlPoint1: NSPoint(x: 72.666667, y: 36), controlPoint2: NSPoint(x: 76, y: 39.333333))
    path.curve(to: NSPoint(x: 66, y: 56), controlPoint1: NSPoint(x: 76, y: 52.666667), controlPoint2: NSPoint(x: 72.666667, y: 56))
    path.line(to: NSPoint(x: 20, y: 56))
    path.line(to: NSPoint(x: 20, y: 90))
    path.curve(to: NSPoint(x: 10, y: 100), controlPoint1: NSPoint(x: 20, y: 96.666667), controlPoint2: NSPoint(x: 16.666667, y: 100))
    path.curve(to: NSPoint(x: 0, y: 90), controlPoint1: NSPoint(x: 3.333333, y: 100), controlPoint2: NSPoint(x: 0, y: 96.666667))
    path.line(to: NSPoint(x: 0, y: 46))
    path.curve(to: NSPoint(x: 10, y: 36), controlPoint1: NSPoint(x: 0, y: 39.333333), controlPoint2: NSPoint(x: 3.333333, y: 36))
    path.close()
    return path
}

func render(pixels: Int, tile: Bool = true) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let context = NSGraphicsContext.current!.cgContext
    context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    context.translateBy(x: 0, y: 1024)
    context.scaleBy(x: 1, y: -1)
    if tile {
        let shape = NSBezierPath(roundedRect: NSRect(x: 44, y: 44, width: 936, height: 936), xRadius: 218, yRadius: 218)
        NSGradient(colors: [NSColor(white: 0.995, alpha: 1), NSColor(white: 0.89, alpha: 1)])!.draw(in: shape, angle: 75)
        NSColor.white.withAlphaComponent(0.8).setStroke()
        shape.lineWidth = 3; shape.stroke()
        let inset = NSBezierPath(roundedRect: NSRect(x: 54, y: 54, width: 916, height: 916), xRadius: 210, yRadius: 210)
        NSColor(white: 0, alpha: 0.035).setStroke()
        inset.lineWidth = 1; inset.stroke()
    }
    let mark = markPath()
    var transform = AffineTransform()
    let scale: CGFloat = tile ? 4.8 : 8.8
    transform.scale(scale)
    mark.transform(using: transform)
    transform = AffineTransform(translationByX: tile ? 272 : 72, byY: tile ? 272 : 72)
    mark.transform(using: transform)
    if tile {
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.shadowBlurRadius = 16
        shadow.shadowOffset = NSSize(width: 0, height: -12)
        shadow.set()
        NSColor(white: 0.16, alpha: 1).setFill(); mark.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGradient(colors: [NSColor(white: 0.10, alpha: 1), NSColor(white: 0.25, alpha: 1)])!.draw(in: mark, angle: 60)
    } else {
        NSColor(white: 0.12, alpha: 1).setFill(); mark.fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try render(pixels: size * scale).write(to: iconset.appendingPathComponent(name))
    }
}
try render(pixels: 1024).write(to: output.appendingPathComponent("AppIcon.png"))
try render(pixels: 512, tile: false).write(to: output.appendingPathComponent("BrandMark.png"))

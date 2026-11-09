import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let context = NSGraphicsContext.current!.cgContext
        context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
        let shape = NSBezierPath(roundedRect: NSRect(x: 44, y: 44, width: 936, height: 936), xRadius: 218, yRadius: 218)
        NSGradient(colors: [NSColor(red: 0.035, green: 0.12, blue: 0.14, alpha: 1), NSColor(red: 0.14, green: 0.28, blue: 0.27, alpha: 1)])!.draw(in: shape, angle: 65)
        NSColor.white.withAlphaComponent(0.16).setStroke(); shape.lineWidth = 3; shape.stroke()
        let glass = NSBezierPath(roundedRect: NSRect(x: 180, y: 260, width: 664, height: 510), xRadius: 118, yRadius: 118)
        NSColor.white.withAlphaComponent(0.08).setFill(); glass.fill()
        NSColor.white.withAlphaComponent(0.25).setStroke(); glass.lineWidth = 4; glass.stroke()
        let heights: [CGFloat] = [104, 220, 308, 174, 252]
        for (index, height) in heights.enumerated() {
            let bar = NSBezierPath(roundedRect: NSRect(x: 300 + CGFloat(index) * 91, y: 515 - height / 2, width: 42, height: height), xRadius: 21, yRadius: 21)
            NSColor(red: 0.64, green: 0.97, blue: 0.83, alpha: 1).setFill(); bar.fill()
        }
        let line = NSBezierPath(roundedRect: NSRect(x: 342, y: 180, width: 340, height: 16), xRadius: 8, yRadius: 8)
        NSColor.white.withAlphaComponent(0.4).setFill(); line.fill()
        NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
    }
}

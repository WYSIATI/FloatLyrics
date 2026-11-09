import AppKit
import AVFoundation
import CoreVideo
import Foundation

// Editable, deterministic motion film. Product scenes are native app captures.
let args = CommandLine.arguments
func argument(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), args.indices.contains(i + 1) else { return nil }
    return args[i + 1]
}
let output = argument("--output") ?? "dist/FloatLyrics-launch-silent.mp4"
let draft = args.contains("--draft")
let width = draft ? 960 : 1920, height = draft ? 540 : 1080
let fps: Int32 = draft ? 15 : 30
let duration = 48.0
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("marketing/assets")
let ink = NSColor(srgbRed: 0.09, green: 0.09, blue: 0.085, alpha: 1)
let paper = NSColor(srgbRed: 0.98, green: 0.98, blue: 0.97, alpha: 1)
let muted = NSColor(white: 0.48, alpha: 1)
let amber = NSColor(srgbRed: 0.96, green: 0.78, blue: 0.48, alpha: 1)

func load(_ name: String) -> CGImage {
    let url = assets.appendingPathComponent(name)
    guard let image = NSImage(contentsOf: url),
          let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        fatalError("Missing native capture: \(url.path)")
    }
    return cg
}
let main = load("window-main.jpg"), soft = load("window-soft.jpg")
let settings = load("settings-root.jpg")
let compactSource = load("island-compact.jpg"), expandedSource = load("island-expanded.jpg")
let compact = compactSource.cropping(to: CGRect(x: 140, y: 0, width: 640, height: 112))!
let expanded = expandedSource.cropping(to: CGRect(x: 20, y: 0, width: 880, height: 272))!
let icon = load("app-icon.png")
func clamp(_ x: Double) -> Double { min(1, max(0, x)) }
func ease(_ x: Double) -> Double { let v = clamp(x); return 1 - pow(1 - v, 3) }
func smooth(_ x: Double) -> Double { let v = clamp(x); return v * v * (3 - 2 * v) }
func mix(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

func fill(_ c: CGContext, _ rect: CGRect, _ color: NSColor, radius: CGFloat = 0) {
    c.setFillColor(color.cgColor)
    c.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    c.fillPath()
}
func text(_ c: CGContext, _ value: String, x: Double, y: Double, w: Double, size: Double,
          weight: NSFont.Weight = .semibold, color: NSColor = ink,
          align: NSTextAlignment = .left, alpha: Double = 1) {
    c.saveGState(); c.setAlpha(alpha)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = align; paragraph.lineSpacing = size * 0.02
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color, .paragraphStyle: paragraph,
        .kern: size > 60 ? -size * 0.045 : -size * 0.015
    ]
    NSAttributedString(string: value, attributes: attributes)
        .draw(in: CGRect(x: x, y: y, width: w, height: size * 3.5))
    c.restoreGState()
}
func reveal(_ c: CGContext, _ value: String, x: Double, y: Double, w: Double, size: Double,
            time: Double, delay: Double = 0, color: NSColor = ink,
            align: NSTextAlignment = .left, weight: NSFont.Weight = .semibold) {
    let p = ease((time - delay) / 0.65)
    text(c, value, x: x, y: y + (1 - p) * 65, w: w, size: size, weight: weight,
         color: color, align: align, alpha: p)
}
func image(_ c: CGContext, _ image: CGImage, _ rect: CGRect, radius: Double = 0,
           alpha: Double = 1, shadow: Bool = false) {
    guard alpha > 0.001 else { return }
    c.saveGState()
    c.setAlpha(alpha)
    if shadow {
        c.setShadow(offset: CGSize(width: 0, height: 24), blur: 55,
                    color: NSColor.black.withAlphaComponent(0.12).cgColor)
        fill(c, rect.insetBy(dx: 2, dy: 2), .white, radius: radius)
        c.setShadow(offset: .zero, blur: 0, color: nil)
    }
    c.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    c.clip(); c.setAlpha(alpha)
    // Images keep their upright orientation in the top-left drawing coordinate system.
    c.translateBy(x: rect.minX, y: rect.maxY); c.scaleBy(x: 1, y: -1)
    c.draw(image, in: CGRect(origin: .zero, size: rect.size))
    c.restoreGState()
}
func note(_ c: CGContext, x: Double, y: Double, scale: Double = 1, angle: Double = 0, alpha: Double = 1) {
    c.saveGState(); c.translateBy(x: x, y: y); c.rotate(by: angle); c.scaleBy(x: scale, y: scale); c.setAlpha(alpha)
    fill(c, CGRect(x: -3, y: -38, width: 9, height: 48), ink, radius: 4)
    fill(c, CGRect(x: 4, y: -39, width: 28, height: 9), ink, radius: 4)
    c.setFillColor(ink.cgColor); c.fillEllipse(in: CGRect(x: -24, y: 0, width: 30, height: 21))
    c.restoreGState()
}
func badge(_ c: CGContext, dark: Bool = false) {
    text(c, "FloatLyrics", x: 84, y: 54, w: 250, size: 22, weight: .medium,
         color: dark ? .white : ink)
    text(c, "YOUR MUSIC, A LITTLE CLOSER.", x: 1310, y: 59, w: 525, size: 15,
         weight: .medium, color: dark ? NSColor(white: 0.65, alpha: 1) : muted, align: .right)
}
func grid(_ c: CGContext, time: Double, dark: Bool = false) {
    fill(c, CGRect(x: 0, y: 0, width: 1920, height: 1080), dark ? ink : paper)
    c.setFillColor((dark ? NSColor.white : NSColor.black).withAlphaComponent(dark ? 0.045 : 0.055).cgColor)
    for x in stride(from: 24.0, to: 1920.0, by: 32.0) {
        for y in stride(from: 24.0, to: 1080.0, by: 32.0) {
            c.fillEllipse(in: CGRect(x: x, y: y, width: 1.7, height: 1.7))
        }
    }
}
func workspace(_ c: CGContext, rect r: CGRect, title: String) {
    c.saveGState()
    c.setShadow(offset: CGSize(width: 0, height: 25), blur: 65, color: NSColor.black.withAlphaComponent(0.08).cgColor)
    fill(c, r, NSColor(white: 0.95, alpha: 1), radius: 28)
    c.setShadow(offset: .zero, blur: 0, color: nil)
    c.addPath(CGPath(roundedRect: r, cornerWidth: 28, cornerHeight: 28, transform: nil)); c.clip()
    fill(c, CGRect(x: r.minX + 230, y: r.minY + 62, width: r.width - 230, height: r.height), .white)
    fill(c, CGRect(x: r.minX, y: r.minY, width: r.width, height: 62), NSColor(white: 0.92, alpha: 1))
    for i in 0..<3 {
        c.setFillColor(NSColor(white: 0.7 + Double(i) * 0.045, alpha: 1).cgColor)
        c.fillEllipse(in: CGRect(x: r.minX + 25 + Double(i) * 24, y: r.minY + 24, width: 13, height: 13))
    }
    text(c, "Notes", x: r.minX + 25, y: r.minY + 102, w: 170, size: 23, color: muted)
    for i in 0..<6 {
        fill(c, CGRect(x: r.minX + 26, y: r.minY + 158 + Double(i) * 52, width: i == 0 ? 154 : 110 + Double(i % 3) * 14, height: 13),
             NSColor(white: i == 0 ? 0.78 : 0.86, alpha: 1), radius: 6)
    }
    text(c, title, x: r.minX + 290, y: r.minY + 112, w: r.width - 345, size: 45)
    text(c, "A little space for good work.", x: r.minX + 293, y: r.minY + 183, w: 680, size: 25, weight: .regular, color: muted)
    for i in 0..<9 {
        fill(c, CGRect(x: r.minX + 294, y: r.minY + 262 + Double(i) * 35,
                       width: min(r.width - 360, 720 - Double(i % 4) * 105), height: 10),
             NSColor(white: 0.9, alpha: 1), radius: 5)
    }
    c.restoreGState()
}
func islandPath(_ rect: CGRect, expanded: Double) -> CGPath {
    let p = CGMutablePath()
    let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
    let s = mix(10, 24, expanded), b = mix(24, 44, expanded)
    p.move(to: CGPoint(x: x, y: y))
    p.addCurve(to: CGPoint(x: x+s, y: y+s), control1: CGPoint(x: x+s*0.8, y: y), control2: CGPoint(x: x+s, y: y+s*0.2))
    p.addLine(to: CGPoint(x: x+s, y: y+h-b))
    p.addQuadCurve(to: CGPoint(x: x+s+b, y: y+h), control: CGPoint(x: x+s, y: y+h))
    p.addLine(to: CGPoint(x: x+w-s-b, y: y+h))
    p.addQuadCurve(to: CGPoint(x: x+w-s, y: y+h-b), control: CGPoint(x: x+w-s, y: y+h))
    p.addLine(to: CGPoint(x: x+w-s, y: y+s))
    p.addCurve(to: CGPoint(x: x+w, y: y), control1: CGPoint(x: x+w-s, y: y+s*0.2), control2: CGPoint(x: x+w-s*0.8, y: y))
    p.closeSubpath(); return p
}
func nativeIsland(_ c: CGContext, center: Double, top: Double, scale: Double, expansion: Double) {
    let w = mix(640, 880, expansion) * scale, h = mix(112, 272, expansion) * scale
    let rect = CGRect(x: center-w/2, y: top, width: w, height: h)
    c.saveGState()
    c.addPath(islandPath(rect, expanded: expansion)); c.clip()
    fill(c, rect, .black)
    if expansion < 1 { image(c, compact, rect, alpha: 1-expansion) }
    if expansion > 0 { image(c, expanded, rect, alpha: expansion) }
    // The physical camera is black. This also excludes capture-pointer overlays in the camera row.
    fill(c, CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 64*scale), .black)
    if expansion > 0.95 {
        // Repaint only the metadata strip to remove the capture pointer; the lyric body remains native.
        fill(c, CGRect(x: rect.minX+28*scale, y: rect.minY+64*scale, width: rect.width-56*scale, height: 72*scale), NSColor(white: 0.102, alpha: 1))
        text(c, "A little room to sing · FloatLyrics · Preview", x: rect.minX, y: rect.minY+77*scale,
             w: rect.width, size: 20*scale, weight: .medium, color: NSColor(white: 0.5, alpha: 1), align: .center)
    }
    c.restoreGState()
}
func cursor(_ c: CGContext, x: Double, y: Double, pulse: Double) {
    c.saveGState(); c.translateBy(x: x, y: y)
    let p = CGMutablePath()
    p.move(to: .zero); p.addLine(to: CGPoint(x: 0, y: 44)); p.addLine(to: CGPoint(x: 12, y: 33))
    p.addLine(to: CGPoint(x: 21, y: 52)); p.addLine(to: CGPoint(x: 29, y: 48))
    p.addLine(to: CGPoint(x: 21, y: 29)); p.addLine(to: CGPoint(x: 39, y: 27)); p.closeSubpath()
    c.setShadow(offset: CGSize(width: 0, height: 2), blur: 7, color: NSColor.black.withAlphaComponent(0.2).cgColor)
    c.addPath(p); c.setFillColor(NSColor.white.cgColor); c.setStrokeColor(ink.cgColor); c.setLineWidth(2); c.drawPath(using: .fillStroke)
    if pulse > 0 {
        c.setShadow(offset: .zero, blur: 0, color: nil)
        c.setStrokeColor(amber.withAlphaComponent(1-pulse).cgColor); c.setLineWidth(4)
        c.strokeEllipse(in: CGRect(x: -pulse*60, y: -pulse*60, width: pulse*120, height: pulse*120))
    }
    c.restoreGState()
}
func render(_ c: CGContext, t: Double) {
    let dark = t >= 36 && t < 41
    grid(c, time: t, dark: dark)
    if t < 41 { badge(c, dark: dark) }
    switch t {
    case ..<3:
        let s = t
        reveal(c, "Know the song.", x: 180, y: 385, w: 1560, size: 144, time: s, align: .center)
        reveal(c, "Your playlist is on.", x: 300, y: 595, w: 1320, size: 35, time: s, delay: 0.35, color: muted, align: .center, weight: .regular)
        for i in 0..<4 {
            let a = Double(i) * 1.5 + t * 0.4
            note(c, x: 330 + Double(i)*425, y: 260 + sin(a)*40, scale: 0.75, angle: sin(a)*0.2, alpha: ease((s-0.1*Double(i))/0.6)*0.55)
        }
    case ..<6:
        let s = t-3
        reveal(c, "Lose the", x: 200, y: 280, w: 1520, size: 142, time: s, align: .center)
        reveal(c, "next line?", x: 200, y: 450, w: 1520, size: 154, time: s, delay: 0.18, align: .center)
        let p = ease((s-0.45)/0.7)
        fill(c, CGRect(x: 600, y: 665, width: 720*p, height: 14), amber, radius: 7)
    case ..<9:
        let s = t-6, p = ease(s/0.8)
        image(c, icon, CGRect(x: 240, y: 405+(1-p)*100, width: 190, height: 190), radius: 42, alpha: p)
        reveal(c, "Meet", x: 480, y: 325, w: 1000, size: 43, time: s, color: muted, weight: .regular)
        reveal(c, "FloatLyrics.", x: 470, y: 410, w: 1200, size: 142, time: s, delay: 0.12)
        reveal(c, "The words, a little closer.", x: 480, y: 610, w: 1150, size: 37, time: s, delay: 0.35, color: muted, weight: .regular)
    case ..<16:
        let s = t-9
        reveal(c, "Keep your flow.", x: 100, y: 140, w: 1600, size: 96, time: s)
        reveal(c, "The words stay beside your work.", x: 104, y: 264, w: 1600, size: 35, time: s, delay: 0.15, color: muted, weight: .regular)
        let p = ease((s-0.25)/0.9)
        workspace(c, rect: CGRect(x: 120, y: 390+(1-p)*160, width: 1640, height: 600), title: "A good day, in progress.")
        let q = ease((s-0.7)/0.9)
        image(c, main, CGRect(x: 900+(1-q)*220, y: 480+sin(s*0.55)*6, width: 800, height: 448), radius: 60, alpha: q, shadow: true)
    case ..<21:
        let s = t-16
        reveal(c, "Your player. Your lyrics.", x: 120, y: 155, w: 1680, size: 92, time: s, align: .center)
        let p = ease((s-0.2)/0.8)
        for (i, name) in ["Spotify", "Apple Music"].enumerated() {
            let x = 390.0 + Double(i)*600
            fill(c, CGRect(x: x, y: 330+(1-p)*55, width: 540, height: 112), .white, radius: 56)
            text(c, name, x: x, y: 355+(1-p)*55, w: 540, size: 43, weight: .medium, align: .center, alpha: p)
        }
        image(c, main, CGRect(x: 560, y: 520+(1-p)*80, width: 800, height: 448), radius: 60, alpha: p, shadow: true)
    case ..<29:
        let s = t-21
        reveal(c, "Meet your notch.", x: 120, y: 150, w: 1680, size: 96, time: s, align: .center)
        reveal(c, "One line. Out of your way.", x: 120, y: 280, w: 1680, size: 35, time: s, delay: 0.2, color: muted, align: .center, weight: .regular)
        let p = ease((s-0.35)/0.9), top = 410+(1-p)*230
        fill(c, CGRect(x: 110, y: top-12, width: 1700, height: 850), ink, radius: 38)
        workspace(c, rect: CGRect(x: 124, y: top, width: 1672, height: 830), title: "Room to focus.")
        let expansion = smooth((s-2.9)/0.5) * (1-smooth((s-5.4)/0.5))
        nativeIsland(c, center: 960, top: top, scale: 1, expansion: expansion)
        if s > 2.4 && s < 4.5 {
            let k = ease((s-2.4)/0.5)
            cursor(c, x: mix(1420, 1220, k), y: mix(top+340, top+88, k), pulse: s > 2.9 && s < 3.3 ? (s-2.9)/0.4 : 0)
        }
    case ..<36:
        let s = t-29, p = ease((s-0.3)/0.8)
        reveal(c, "As quiet as you like.", x: 100, y: 145, w: 1720, size: 92, time: s)
        reveal(c, "Opacity. Text color. Your call.", x: 104, y: 270, w: 1500, size: 35, time: s, delay: 0.18, color: muted, weight: .regular)
        image(c, settings, CGRect(x: 135, y: 440, width: 540, height: 416.6), radius: 46, alpha: p, shadow: true)
        image(c, soft, CGRect(x: 805+(1-p)*160, y: 440, width: 960, height: 537.6), radius: 72, alpha: p, shadow: true)
    case ..<41:
        let s = t-36
        reveal(c, "Work in flow.", x: 160, y: 285, w: 1600, size: 126, time: s, color: .white, align: .center)
        reveal(c, "Sing along.", x: 160, y: 455, w: 1600, size: 138, time: s, delay: 0.2, color: .white, align: .center)
        for i in 0..<4 {
            let p = ease((s-0.3-Double(i)*0.1)/0.8)
            c.saveGState(); c.setAlpha(p)
            fill(c, CGRect(x: 660+Double(i)*160, y: 732+sin(s*2+Double(i))*15, width: 92, height: 9+Double(i%3)*10), NSColor(white: 0.72, alpha: 1), radius: 12)
            c.restoreGState()
        }
    default:
        let s = t-41, p = ease(s/0.8)
        image(c, icon, CGRect(x: 886, y: 150+(1-p)*60, width: 148, height: 148), radius: 34, alpha: p)
        reveal(c, "FloatLyrics.", x: 200, y: 335, w: 1520, size: 116, time: s, delay: 0.05, align: .center)
        reveal(c, "Free. Open source. Made for Mac.", x: 200, y: 500, w: 1520, size: 38, time: s, delay: 0.25, color: muted, align: .center, weight: .regular)
        let q = ease((s-0.5)/0.6)
        c.saveGState(); c.setAlpha(q)
        fill(c, CGRect(x: 670, y: 610, width: 580, height: 96), ink, radius: 48)
        text(c, "Download for macOS", x: 670, y: 633, w: 580, size: 35, weight: .medium, color: .white, align: .center)
        c.restoreGState()
        reveal(c, "github.com/WYSIATI/FloatLyrics", x: 180, y: 767, w: 1560, size: 30, time: s, delay: 0.75, align: .center, weight: .medium)
        reveal(c, "macOS 14+  ·  Liquid Glass on macOS 26+", x: 200, y: 927, w: 1520, size: 23, time: s, delay: 1, color: muted, align: .center, weight: .regular)
    }
}

func drawFrame(_ c: CGContext, t: Double) {
    c.saveGState()
    c.translateBy(x: 0, y: CGFloat(height)); c.scaleBy(x: CGFloat(width)/1920, y: -CGFloat(height)/1080)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: c, flipped: true)
    render(c, t: t)
    NSGraphicsContext.restoreGraphicsState(); c.restoreGState()
}

if let value = argument("--frame"), let time = Double(value) {
    let space = CGColorSpaceCreateDeviceRGB()
    let c = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                      bytesPerRow: width*4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    drawFrame(c, t: time)
    let bitmap = NSBitmapImageRep(cgImage: c.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
    print("Rendered frame at \(time)s → \(output)")
} else {
    let url = URL(fileURLWithPath: output)
    try? FileManager.default.removeItem(at: url)
    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: draft ? 2_000_000 : 8_000_000,
                                         AVVideoMaxKeyFrameIntervalKey: Int(fps)*2,
                                         AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel]
    ])
    input.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height,
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
    ])
    writer.add(input); writer.startWriting(); writer.startSession(atSourceTime: .zero)
    let count = Int(duration*Double(fps))
    for index in 0..<count {
        while !input.isReadyForMoreMediaData {
            if writer.status == .failed { fatalError(writer.error!.localizedDescription) }
            Thread.sleep(forTimeInterval: 0.002)
        }
        try autoreleasepool {
            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
            guard let pixel = buffer else { throw NSError(domain: "Render", code: 1) }
            CVPixelBufferLockBaseAddress(pixel, [])
            let c = CGContext(data: CVPixelBufferGetBaseAddress(pixel), width: width, height: height,
                              bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixel),
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)!
            drawFrame(c, t: Double(index)/Double(fps))
            CVPixelBufferUnlockBaseAddress(pixel, [])
            guard adaptor.append(pixel, withPresentationTime: CMTime(value: Int64(index), timescale: fps)) else {
                throw writer.error ?? NSError(domain: "Render", code: 2)
            }
        }
        if index % (Int(fps)*4) == 0 { print("Rendered \(index/Int(fps)) / \(Int(duration)) seconds"); fflush(stdout) }
    }
    input.markAsFinished()
    let semaphore = DispatchSemaphore(value: 0)
    writer.finishWriting { semaphore.signal() }
    semaphore.wait()
    guard writer.status == .completed else { fatalError(writer.error?.localizedDescription ?? "Movie incomplete") }
    print("Rendered \(count) frames → \(output)")
}

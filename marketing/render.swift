import AppKit
import AVFoundation
import CoreVideo
import CoreImage
import Foundation

// Product scenes are decoded from real screen recordings. No recreated app or workspace UI.
let args = CommandLine.arguments
func argument(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), args.indices.contains(i + 1) else { return nil }
    return args[i + 1]
}
let output = argument("--output") ?? "build/Float-Lyrics-launch-silent.mp4"
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
let icon = load("app-icon.png")
let graphicsOnly = args.contains("--graphics-only")
let footageDirectory = URL(fileURLWithPath: argument("--footage") ?? "build/launch-footage")
final class RealFootage {
    private let reader: AVAssetReader
    private let output: AVAssetReaderTrackOutput
    private let context = CIContext(options: [.cacheIntermediates: false])
    private var lastImage: CGImage?
    private var nextSample: CMSampleBuffer?
    init(_ name: String, minimumDuration: Double) async throws {
        let url = footageDirectory.appendingPathComponent(name + ".mp4")
        guard FileManager.default.fileExists(atPath: url.path) else {
            fatalError("Missing real recording: " + url.path + ". Prepare reviewed footage before rendering.")
        }
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard CMTimeGetSeconds(duration) >= minimumDuration,
              let track = tracks.first else {
            fatalError("Recording is shorter than the scene: " + name)
        }
        reader = try AVAssetReader(asset: asset)
        output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        reader.add(output)
        guard reader.startReading() else { throw reader.error! }
        nextSample = output.copyNextSampleBuffer()
    }
    func frame(at seconds: Double) -> CGImage {
        while let sample = nextSample,
              CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample)) <= seconds + 1.0 / 60 {
            if let pixel = CMSampleBufferGetImageBuffer(sample) {
                let image = CIImage(cvPixelBuffer: pixel)
                lastImage = context.createCGImage(image, from: image.extent)
            }
            nextSample = output.copyNextSampleBuffer()
        }
        guard let image = lastImage else { fatalError("Could not decode the real recording.") }
        return image
    }
}
let floatingFootage: RealFootage?
let islandFootage: RealFootage?
let settingsFootage: RealFootage?
if graphicsOnly {
    floatingFootage = nil; islandFootage = nil; settingsFootage = nil
} else {
    floatingFootage = try await RealFootage("floating", minimumDuration: 15)
    islandFootage = try await RealFootage("island", minimumDuration: 12)
    settingsFootage = try await RealFootage("settings", minimumDuration: 15)
}
// Usage instructions are burned into the movie, so they remain visible on X with sound off.
let walkthrough: [(start: Double, end: Double, title: String, detail: String)] = [
    (0, 4, "Your music, a little closer.", "Live lyrics beside your work."),
    (4, 8, "1. Choose your player", "••• → Music Player → Spotify or Apple Music"),
    (8, 12, "2. Play a song", "Play in the desktop app. Allow Automation if macOS asks."),
    (12, 15, "Keep working. Lyrics follow.", "Live lyrics stay beside your work automatically."),
    (15, 20, "3. Move to your notch", "••• → Move to Dynamic Island"),
    (20, 24, "One line at a time", "Click the island to expand its controls."),
    (24, 27, "Back to the window?", "Expand the island, then click the window arrow."),
    (27, 32, "4. Make it comfortable", "••• → Settings → Appearance"),
    (32, 36, "Fade the background", "Choose Window or Island, then adjust opacity. Lyrics stay crisp."),
    (36, 39, "Choose your lyric color", "Select a swatch. More options has custom colors."),
    (39, 42, "Return to your work", "Your changes save automatically. Keep listening.")
]
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
    text(c, "Float Lyrics", x: 84, y: 54, w: 250, size: 22, weight: .medium,
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
func render(_ c: CGContext, t: Double) {
    grid(c, time: t)
    if t < 42 {
        badge(c)
        let source: RealFootage?
        let localTime: Double
        if t < 15 {
            source = floatingFootage; localTime = t
        } else if t < 27 {
            source = islandFootage; localTime = t - 15
        } else {
            source = settingsFootage; localTime = t - 27
        }
        if let instruction = walkthrough.first(where: { $0.start <= t && t < $0.end }) {
            text(c, instruction.title, x: 84, y: 116, w: 1752, size: 59)
            text(c, instruction.detail, x: 88, y: 196, w: 1744, size: 28, weight: .regular, color: muted)
        }
        if let source {
            let frame = source.frame(at: localTime)
            let area = CGRect(x: 80, y: 264, width: 1760, height: 752)
            let scale = min(area.width / Double(frame.width), area.height / Double(frame.height))
            let rect = CGRect(x: area.midX - Double(frame.width) * scale / 2,
                              y: area.midY - Double(frame.height) * scale / 2,
                              width: Double(frame.width) * scale, height: Double(frame.height) * scale)
            image(c, frame, rect, radius: 18, shadow: true)
        }
        if t < 4 {
            let p = ease(t / 0.5) * (1 - smooth((t - 3) / 0.7))
            c.saveGState(); c.setAlpha(p)
            fill(c, CGRect(x: 420, y: 415, width: 1080, height: 225), paper, radius: 32)
            text(c, "Float Lyrics", x: 460, y: 440, w: 1000, size: 110, align: .center)
            text(c, "Your music, a little closer.", x: 460, y: 577, w: 1000, size: 31,
                 weight: .regular, color: muted, align: .center)
            c.restoreGState()
        }
    } else {
        let s = t - 42, p = ease(s / 0.6)
        image(c, icon, CGRect(x: 886, y: 150 + (1-p)*60, width: 148, height: 148), radius: 34, alpha: p)
        reveal(c, "Float Lyrics", x: 200, y: 335, w: 1520, size: 116, time: s, align: .center)
        reveal(c, "Free. Open source. Made for Mac.", x: 200, y: 500, w: 1520, size: 38,
               time: s, delay: 0.15, color: muted, align: .center, weight: .regular)
        let q = ease((s - 0.35) / 0.6)
        c.saveGState(); c.setAlpha(q)
        fill(c, CGRect(x: 670, y: 610, width: 580, height: 96), ink, radius: 48)
        text(c, "Download for macOS", x: 670, y: 633, w: 580, size: 35, weight: .medium, color: .white, align: .center)
        c.restoreGState()
        reveal(c, "github.com/WYSIATI/FloatLyrics", x: 180, y: 767, w: 1560, size: 30,
               time: s, delay: 0.6, align: .center, weight: .medium)
        reveal(c, "Download → Applications → Open", x: 200, y: 855, w: 1520, size: 25,
               time: s, delay: 0.75, color: muted, align: .center, weight: .regular)
        reveal(c, "macOS 14+  ·  Liquid Glass on macOS 26+", x: 200, y: 927, w: 1520, size: 23,
               time: s, delay: 0.8, color: muted, align: .center, weight: .regular)
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
            try await Task.sleep(for: .milliseconds(2))
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
    await writer.finishWriting()
    guard writer.status == .completed else { fatalError(writer.error?.localizedDescription ?? "Movie incomplete") }
    print("Rendered \(count) frames → \(output)")
}

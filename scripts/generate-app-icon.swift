#!/usr/bin/env swift

import AppKit
import Foundation

private struct IconSlot {
    let size: Int
    let scale: Int
    let filename: String

    var pixels: Int { size * scale }
}

private let slots = [
    IconSlot(size: 16, scale: 1, filename: "icon_16x16.png"),
    IconSlot(size: 16, scale: 2, filename: "icon_16x16@2x.png"),
    IconSlot(size: 32, scale: 1, filename: "icon_32x32.png"),
    IconSlot(size: 32, scale: 2, filename: "icon_32x32@2x.png"),
    IconSlot(size: 128, scale: 1, filename: "icon_128x128.png"),
    IconSlot(size: 128, scale: 2, filename: "icon_128x128@2x.png"),
    IconSlot(size: 256, scale: 1, filename: "icon_256x256.png"),
    IconSlot(size: 256, scale: 2, filename: "icon_256x256@2x.png"),
    IconSlot(size: 512, scale: 1, filename: "icon_512x512.png"),
    IconSlot(size: 512, scale: 2, filename: "icon_512x512@2x.png")
]

private let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
private let appIconURL = rootURL
    .appendingPathComponent("StarMagpie")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")
private let docsAssetURL = rootURL
    .appendingPathComponent("docs")
    .appendingPathComponent("assets")

try FileManager.default.createDirectory(at: appIconURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: docsAssetURL, withIntermediateDirectories: true)

private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

private func starPath(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat, points: Int = 5) -> NSBezierPath {
    let path = NSBezierPath()
    for index in 0..<(points * 2) {
        let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
        let angle = CGFloat(index) * .pi / CGFloat(points) + .pi / 2
        let point = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
        if index == 0 {
            path.move(to: point)
        } else {
            path.line(to: point)
        }
    }
    path.close()
    return path
}

private func drawIcon(size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    bitmap.size = NSSize(width: size, height: size)

    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw CocoaError(.fileWriteUnknown)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
    context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    context.cgContext.setShouldAntialias(true)
    context.cgContext.setAllowsAntialiasing(true)

    drawBackground()
    drawStar()
    drawMagpie()
    drawForegroundHighlights()

    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

private func drawBackground() {
    let backgroundPath = NSBezierPath(
        roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896),
        xRadius: 210,
        yRadius: 210
    )

    let shadow = NSShadow()
    shadow.shadowColor = color(0, 0, 0, 0.28)
    shadow.shadowBlurRadius = 38
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.set()

    color(9, 14, 30).setFill()
    backgroundPath.fill()
    NSShadow().set()

    NSGradient(colors: [
        color(10, 17, 36),
        color(20, 55, 86),
        color(20, 128, 136)
    ])?.draw(in: backgroundPath, angle: 315)

    backgroundPath.addClip()

    color(255, 255, 255, 0.12).setFill()
    NSBezierPath(ovalIn: NSRect(x: 114, y: 692, width: 520, height: 300)).fill()

    color(45, 212, 191, 0.18).setFill()
    NSBezierPath(ovalIn: NSRect(x: 486, y: 92, width: 520, height: 360)).fill()

    color(7, 10, 22, 0.24).setFill()
    NSBezierPath(ovalIn: NSRect(x: -80, y: -120, width: 640, height: 340)).fill()
}

private func drawStar() {
    let shadow = NSShadow()
    shadow.shadowColor = color(76, 37, 0, 0.35)
    shadow.shadowBlurRadius = 18
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()

    let star = starPath(center: CGPoint(x: 382, y: 568), outerRadius: 240, innerRadius: 102)
    NSGradient(colors: [
        color(255, 238, 147),
        color(255, 184, 42),
        color(245, 132, 31)
    ])?.draw(in: star, angle: 90)

    NSShadow().set()

    color(255, 255, 255, 0.38).setStroke()
    star.lineWidth = 16
    star.stroke()
}

private func drawMagpie() {
    drawTail()
    drawBody()
    drawWing()
    drawHead()
    drawBeakAndEye()
}

private func drawTail() {
    let tail = NSBezierPath()
    tail.move(to: CGPoint(x: 570, y: 404))
    tail.curve(to: CGPoint(x: 896, y: 184), controlPoint1: CGPoint(x: 666, y: 350), controlPoint2: CGPoint(x: 780, y: 246))
    tail.curve(to: CGPoint(x: 906, y: 276), controlPoint1: CGPoint(x: 910, y: 218), controlPoint2: CGPoint(x: 912, y: 248))
    tail.curve(to: CGPoint(x: 626, y: 482), controlPoint1: CGPoint(x: 812, y: 328), controlPoint2: CGPoint(x: 714, y: 404))
    tail.close()

    NSGradient(colors: [
        color(7, 13, 26),
        color(24, 88, 128),
        color(80, 210, 214)
    ])?.draw(in: tail, angle: 215)

    let lowerTail = NSBezierPath()
    lowerTail.move(to: CGPoint(x: 630, y: 374))
    lowerTail.curve(to: CGPoint(x: 910, y: 112), controlPoint1: CGPoint(x: 708, y: 292), controlPoint2: CGPoint(x: 815, y: 178))
    lowerTail.curve(to: CGPoint(x: 884, y: 206), controlPoint1: CGPoint(x: 912, y: 146), controlPoint2: CGPoint(x: 904, y: 180))
    lowerTail.curve(to: CGPoint(x: 604, y: 454), controlPoint1: CGPoint(x: 780, y: 254), controlPoint2: CGPoint(x: 690, y: 350))
    lowerTail.close()

    color(7, 10, 23, 0.96).setFill()
    lowerTail.fill()
}

private func drawBody() {
    let body = NSBezierPath()
    body.move(to: CGPoint(x: 318, y: 422))
    body.curve(to: CGPoint(x: 548, y: 350), controlPoint1: CGPoint(x: 380, y: 350), controlPoint2: CGPoint(x: 480, y: 326))
    body.curve(to: CGPoint(x: 710, y: 488), controlPoint1: CGPoint(x: 640, y: 378), controlPoint2: CGPoint(x: 700, y: 424))
    body.curve(to: CGPoint(x: 584, y: 654), controlPoint1: CGPoint(x: 728, y: 578), controlPoint2: CGPoint(x: 656, y: 638))
    body.curve(to: CGPoint(x: 344, y: 610), controlPoint1: CGPoint(x: 484, y: 674), controlPoint2: CGPoint(x: 378, y: 642))
    body.curve(to: CGPoint(x: 318, y: 422), controlPoint1: CGPoint(x: 298, y: 566), controlPoint2: CGPoint(x: 274, y: 482))
    body.close()

    let shadow = NSShadow()
    shadow.shadowColor = color(0, 0, 0, 0.36)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()

    NSGradient(colors: [
        color(5, 8, 18),
        color(13, 20, 38),
        color(20, 32, 54)
    ])?.draw(in: body, angle: 100)
    NSShadow().set()

    let chest = NSBezierPath()
    chest.move(to: CGPoint(x: 396, y: 426))
    chest.curve(to: CGPoint(x: 570, y: 398), controlPoint1: CGPoint(x: 450, y: 382), controlPoint2: CGPoint(x: 520, y: 380))
    chest.curve(to: CGPoint(x: 632, y: 508), controlPoint1: CGPoint(x: 620, y: 424), controlPoint2: CGPoint(x: 644, y: 462))
    chest.curve(to: CGPoint(x: 454, y: 610), controlPoint1: CGPoint(x: 566, y: 588), controlPoint2: CGPoint(x: 502, y: 624))
    chest.curve(to: CGPoint(x: 396, y: 426), controlPoint1: CGPoint(x: 392, y: 574), controlPoint2: CGPoint(x: 370, y: 488))
    chest.close()

    NSGradient(colors: [
        color(255, 255, 248),
        color(218, 232, 236)
    ])?.draw(in: chest, angle: 92)
}

private func drawWing() {
    let wing = NSBezierPath()
    wing.move(to: CGPoint(x: 432, y: 476))
    wing.curve(to: CGPoint(x: 690, y: 462), controlPoint1: CGPoint(x: 514, y: 408), controlPoint2: CGPoint(x: 616, y: 410))
    wing.curve(to: CGPoint(x: 572, y: 586), controlPoint1: CGPoint(x: 650, y: 540), controlPoint2: CGPoint(x: 628, y: 572))
    wing.curve(to: CGPoint(x: 432, y: 476), controlPoint1: CGPoint(x: 516, y: 596), controlPoint2: CGPoint(x: 454, y: 548))
    wing.close()

    NSGradient(colors: [
        color(26, 71, 120),
        color(42, 173, 200),
        color(176, 238, 245)
    ])?.draw(in: wing, angle: 235)

    color(255, 255, 255, 0.42).setStroke()
    wing.lineWidth = 11
    wing.stroke()
}

private func drawHead() {
    let neck = NSBezierPath()
    neck.move(to: CGPoint(x: 586, y: 590))
    neck.curve(to: CGPoint(x: 700, y: 566), controlPoint1: CGPoint(x: 632, y: 588), controlPoint2: CGPoint(x: 676, y: 578))
    neck.curve(to: CGPoint(x: 648, y: 466), controlPoint1: CGPoint(x: 692, y: 520), controlPoint2: CGPoint(x: 676, y: 490))
    neck.curve(to: CGPoint(x: 548, y: 536), controlPoint1: CGPoint(x: 606, y: 470), controlPoint2: CGPoint(x: 568, y: 500))
    neck.close()
    color(4, 7, 16).setFill()
    neck.fill()

    let head = NSBezierPath(ovalIn: NSRect(x: 576, y: 576, width: 170, height: 154))
    NSGradient(colors: [
        color(6, 9, 20),
        color(16, 26, 44)
    ])?.draw(in: head, angle: 90)
}

private func drawBeakAndEye() {
    let beak = NSBezierPath()
    beak.move(to: CGPoint(x: 716, y: 654))
    beak.line(to: CGPoint(x: 820, y: 620))
    beak.line(to: CGPoint(x: 716, y: 594))
    beak.close()
    NSGradient(colors: [
        color(255, 222, 111),
        color(250, 148, 36)
    ])?.draw(in: beak, angle: 5)

    color(255, 255, 255, 0.95).setFill()
    NSBezierPath(ovalIn: NSRect(x: 668, y: 652, width: 26, height: 26)).fill()

    color(7, 10, 22).setFill()
    NSBezierPath(ovalIn: NSRect(x: 677, y: 661, width: 10, height: 10)).fill()
}

private func drawForegroundHighlights() {
    let shine = NSBezierPath()
    shine.move(to: CGPoint(x: 178, y: 838))
    shine.curve(to: CGPoint(x: 610, y: 880), controlPoint1: CGPoint(x: 304, y: 928), controlPoint2: CGPoint(x: 466, y: 944))
    shine.curve(to: CGPoint(x: 216, y: 758), controlPoint1: CGPoint(x: 466, y: 848), controlPoint2: CGPoint(x: 322, y: 802))
    shine.close()

    color(255, 255, 255, 0.11).setFill()
    shine.fill()
}

for slot in slots {
    let data = try drawIcon(size: slot.pixels)
    let outputURL = appIconURL.appendingPathComponent(slot.filename)
    try data.write(to: outputURL)
    print("Generated \(outputURL.path)")
}

let previewData = try drawIcon(size: 1024)
try previewData.write(to: docsAssetURL.appendingPathComponent("app-icon.png"))
print("Generated \(docsAssetURL.appendingPathComponent("app-icon.png").path)")

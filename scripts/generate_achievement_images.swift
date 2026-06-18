#!/usr/bin/env swift
import AppKit

// Renders one opaque 512x512 PNG per achievement: its SF Symbol in a thematic tier
// color, centered on a dark papyrus gradient with a faint accent ring. Uses Core
// Graphics directly (no lockFocus) so it renders correctly in a headless CLI.
// Game Center requires 512x512 or 1024x1024, flattened, NO transparency.

struct Art {
    let id: String
    let symbol: String
    let accentHex: String
}

let ITEMS: [Art] = [
    Art(id: "first_step", symbol: "book.fill", accentHex: "D8B26A"),
    Art(id: "quiz_whiz", symbol: "checkmark.circle.fill", accentHex: "5FB7B0"),
    Art(id: "enlightened_one", symbol: "star.fill", accentHex: "E8A94E"),
    Art(id: "perfect_understanding", symbol: "medal.fill", accentHex: "CCCCCC"),
    Art(id: "scholar_of_sheol", symbol: "flag.fill", accentHex: "5B93D6"),
    Art(id: "journey_through_duat", symbol: "flag.fill", accentHex: "CBA678"),
    Art(id: "wisdom_seeker", symbol: "star.fill", accentHex: "FFD64A"),
    Art(id: "eternal_student", symbol: "crown.fill", accentHex: "CD7F32"),
    Art(id: "cosmic_explorer", symbol: "crown.fill", accentHex: "CFCFCF"),
    Art(id: "afterlife_master", symbol: "crown.fill", accentHex: "FFD700"),
]

func nscolor(_ hex: String) -> NSColor {
    var v: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&v)
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
                   green: CGFloat((v >> 8) & 0xff) / 255,
                   blue: CGFloat(v & 0xff) / 255, alpha: 1)
}

func symbolCGImage(_ name: String, accent: NSColor) -> CGImage {
    var config = NSImage.SymbolConfiguration(pointSize: 250, weight: .semibold)
    config = config.applying(NSImage.SymbolConfiguration(paletteColors: [accent]))
    guard let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { fatalError("missing symbol \(name)") }
    var rect = CGRect(origin: .zero, size: img.size)
    guard let cg = img.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
        fatalError("no cgImage for \(name)")
    }
    return cg
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/gc-art"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let side = 512
let cs = CGColorSpaceCreateDeviceRGB()

for item in ITEMS {
    guard let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                              bytesPerRow: 0, space: cs,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        fatalError("context")
    }
    let bounds = CGRect(x: 0, y: 0, width: side, height: side)

    let grad = CGGradient(colorsSpace: cs,
                          colors: [nscolor("2E2620").cgColor, nscolor("12100C").cgColor] as CFArray,
                          locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: side / 2, y: side),
                           end: CGPoint(x: side / 2, y: 0), options: [])

    let accent = nscolor(item.accentHex)
    ctx.setStrokeColor(accent.withAlphaComponent(0.5).cgColor)
    ctx.setLineWidth(6)
    ctx.strokeEllipse(in: bounds.insetBy(dx: 46, dy: 46))

    let cg = symbolCGImage(item.symbol, accent: accent)
    let aspect = CGFloat(cg.width) / CGFloat(cg.height)
    let maxDim: CGFloat = 250
    let w = aspect >= 1 ? maxDim : maxDim * aspect
    let h = aspect >= 1 ? maxDim / aspect : maxDim
    let rect = CGRect(x: (CGFloat(side) - w) / 2, y: (CGFloat(side) - h) / 2, width: w, height: h)
    ctx.draw(cg, in: rect)

    guard let outImg = ctx.makeImage() else { fatalError("makeImage") }
    let png = NSBitmapImageRep(cgImage: outImg).representation(using: .png, properties: [:])!
    let path = "\(outDir)/\(item.id).png"
    try! png.write(to: URL(fileURLWithPath: path))
    print("wrote \(path) (\(png.count) bytes)")
}

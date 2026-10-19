// Génère AppIcon.icns : swift scripts/make_icon.swift <dossier de sortie>
import Cocoa

let out = CommandLine.arguments[1]
let iconset = out + "/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

func draw(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Fond : carré arrondi façon macOS, dégradé sombre
    let inset = s * 0.1, rect = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let bg = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)
    NSGradient(starting: NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.24, alpha: 1),
               ending: NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.09, alpha: 1))!.draw(in: bg, angle: -90)

    // Invite de commande « >_ »
    let font = NSFont.monospacedSystemFont(ofSize: rect.width * 0.26, weight: .bold)
    let prompt = NSAttributedString(string: ">_", attributes: [
        .font: font, .foregroundColor: NSColor(calibratedRed: 0.35, green: 0.95, blue: 0.55, alpha: 1)])
    prompt.draw(at: NSPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - rect.width * 0.42))

    // Symbole de pincement
    let cfg = NSImage.SymbolConfiguration(pointSize: rect.width * 0.34, weight: .semibold)
    if let sym = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        let tinted = NSImage(size: sym.size, flipped: false) { r in
            sym.draw(in: r); NSColor.white.set(); r.fill(using: .sourceAtop); return true
        }
        let sz = tinted.size
        tinted.draw(in: NSRect(x: rect.maxX - sz.width - rect.width * 0.12, y: rect.minY + rect.width * 0.12,
                               width: sz.width, height: sz.height))
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! draw(base * scale).write(to: URL(fileURLWithPath: iconset + "/" + name))
    }
}

import AppKit

enum WaftMark {
    static let image = makeImage()

    private static let canvas = NSSize(width: 18, height: 16)
    private static let scale: CGFloat = 0.28

    private static func makeImage() -> NSImage {
        let image = NSImage(size: canvas, flipped: true) { bounds in
            let transform = NSAffineTransform()
            transform.translateX(by: bounds.midX - 50 * scale, yBy: bounds.midY - 49.5 * scale)
            transform.scale(by: scale)

            let path = mark()
            path.transform(using: transform as AffineTransform)
            path.lineWidth = 8 * scale
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            NSColor.black.setStroke()
            path.stroke()

            return true
        }

        image.isTemplate = true

        return image
    }

    private static func mark() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 25, y: 38))
        path.curve(to: NSPoint(x: 29, y: 39), controlPoint: NSPoint(x: 27, y: 36))
        path.line(to: NSPoint(x: 37, y: 60))
        path.curve(to: NSPoint(x: 40, y: 60), controlPoint: NSPoint(x: 38, y: 63))
        path.line(to: NSPoint(x: 47, y: 46))
        path.curve(to: NSPoint(x: 53, y: 46), controlPoint: NSPoint(x: 50, y: 41))
        path.line(to: NSPoint(x: 60, y: 60))
        path.curve(to: NSPoint(x: 63, y: 60), controlPoint: NSPoint(x: 62, y: 63))
        path.line(to: NSPoint(x: 71, y: 39))
        path.curve(to: NSPoint(x: 75, y: 38), controlPoint: NSPoint(x: 73, y: 36))

        return path
    }
}

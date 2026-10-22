import SwiftUI

struct IslandOrb: View {
    enum Style {
        case still
        case scanning
    }

    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let style: Style
    let size: CGFloat
    let tint: Color

    private var dotCount: Int {
        switch style {
        case .still: 56
        case .scanning: 80
        }
    }

    private var isPaused: Bool {
        guard !reducesMotion else { return true }

        return style == .still
    }

    var body: some View {
        TimelineView(.animation(paused: isPaused)) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            Canvas { canvas, area in
                draw(in: &canvas, area: area, time: time)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func draw(in canvas: inout GraphicsContext, area: CGSize, time: TimeInterval) {
        let radius = area.width / 2 - 1

        for dot in OrbDot.sphere(count: dotCount, rotation: rotation(at: time), shine: shine(at: time)) {
            let front = (dot.depth + 1) / 2

            let diameter = (0.8 + 1.2 * front + 0.25 * dot.glow) * size / 18

            let bounds = CGRect(
                x: area.width / 2 + dot.horizontal * radius - diameter / 2,
                y: area.height / 2 + dot.vertical * radius - diameter / 2,
                width: diameter,
                height: diameter,
            )

            canvas.fill(Path(ellipseIn: bounds), with: .color(tint.opacity(opacity(front: front, glow: dot.glow))))
        }
    }

    private func rotation(at time: TimeInterval) -> Double {
        switch style {
        case .still: 0.6
        case .scanning: time * 0.9
        }
    }

    private func shine(at time: TimeInterval) -> Double? {
        switch style {
        case .still: nil
        case .scanning: Shimmer.center(at: time)
        }
    }

    private func opacity(front: Double, glow: Double) -> Double {
        switch style {
        case .still: 0.35 + 0.65 * front
        case .scanning: min(1, 0.15 + 0.45 * front + 0.75 * glow)
        }
    }
}

private struct OrbDot {
    private static let tilt = 0.35
    private static let goldenAngle = Double.pi * (3 - 5.squareRoot())

    let horizontal: Double
    let vertical: Double
    let depth: Double
    let glow: Double

    static func sphere(count: Int, rotation: Double, shine: Double?) -> [Self] {
        let dots = (0 ..< count).map { index in
            let height = 1 - 2 * (Double(index) + 0.5) / Double(count)
            let angle = goldenAngle * Double(index) + rotation

            let ring = (1 - height * height).squareRoot()

            let depth = sin(angle) * ring

            let horizontal = cos(angle) * ring

            return Self(
                horizontal: horizontal,
                vertical: height * cos(tilt) - depth * sin(tilt),
                depth: height * sin(tilt) + depth * cos(tilt),
                glow: glow(at: horizontal, shine: shine),
            )
        }

        return dots.sorted { $0.depth < $1.depth }
    }

    private static func glow(at horizontal: Double, shine: Double?) -> Double {
        guard let shine else { return 0 }

        let position = (horizontal + 1) / 2

        return max(0, 1 - abs(position - shine) / Shimmer.width)
    }
}

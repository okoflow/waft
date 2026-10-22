import SwiftUI

struct IslandOrb: View {
    private static let dotCount = 80
    private static let assemblyDuration: TimeInterval = 0.6
    private static let pulseDuration: TimeInterval = 0.45
    private static let overflow: CGFloat = 6

    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let size: CGFloat
    let appearedAt: Date
    let pulsedAt: Date

    var body: some View {
        TimelineView(.animation(paused: reducesMotion)) { context in
            let date = context.date

            Canvas { canvas, area in
                draw(in: &canvas, area: area, date: date)
            }
            .frame(width: size + Self.overflow, height: size + Self.overflow)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private static func progress(since start: Date, at date: Date, over duration: TimeInterval) -> Double {
        min(1, max(0, date.timeIntervalSince(start) / duration))
    }

    private static func overshoot(_ progress: Double) -> Double {
        let rest = progress - 1

        return 1 + 2.2 * rest * rest * rest + 1.2 * rest * rest
    }

    private func draw(in canvas: inout GraphicsContext, area: CGSize, date: Date) {
        let assembly = assembly(at: date)
        let pulse = pulse(at: date)

        let radius = (size / 2 - 1) * Self.overshoot(assembly) * (1 + 0.06 * pulse)

        let rotation = date.timeIntervalSinceReferenceDate * 0.9

        for dot in OrbDot.sphere(count: Self.dotCount, rotation: rotation) {
            let front = (dot.depth + 1) / 2

            let diameter = (0.6 + 0.9 * front) * (1 + 0.2 * pulse) * size / 18

            let bounds = CGRect(
                x: area.width / 2 + dot.horizontal * radius - diameter / 2,
                y: area.height / 2 + dot.vertical * radius - diameter / 2,
                width: diameter,
                height: diameter,
            )

            let opacity = min(1, 0.3 + 0.7 * front + 0.3 * pulse) * min(1, 2 * assembly)

            canvas.fill(Path(ellipseIn: bounds), with: .color(.white.opacity(opacity)))
        }
    }

    private func assembly(at date: Date) -> Double {
        guard !reducesMotion else { return 1 }

        return Self.progress(since: appearedAt, at: date, over: Self.assemblyDuration)
    }

    private func pulse(at date: Date) -> Double {
        guard !reducesMotion else { return 0 }

        return sin(.pi * Self.progress(since: pulsedAt, at: date, over: Self.pulseDuration))
    }
}

private struct OrbDot {
    private static let tilt = 0.35
    private static let goldenAngle = Double.pi * (3 - 5.squareRoot())

    let horizontal: Double
    let vertical: Double
    let depth: Double

    static func sphere(count: Int, rotation: Double) -> [Self] {
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
            )
        }

        return dots.sorted { $0.depth < $1.depth }
    }
}

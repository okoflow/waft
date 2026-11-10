import SwiftUI

struct ShimmeringText: View {
    private static let width = 0.2
    private static let period: TimeInterval = 1.6

    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let text: String
    var color = Color.white

    var body: some View {
        TimelineView(.animation(paused: reducesMotion)) { context in
            let center = Self.center(at: context.date.timeIntervalSinceReferenceDate)

            Text(text)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: color.opacity(0.35), location: max(0, center - Self.width)),
                            .init(color: color.opacity(0.95), location: min(1, max(0, center))),
                            .init(color: color.opacity(0.35), location: min(1, center + Self.width)),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing,
                    ),
                )
        }
    }

    private static func center(at time: TimeInterval) -> Double {
        let phase = time.truncatingRemainder(dividingBy: period) / period

        return -0.3 + 1.6 * phase
    }
}

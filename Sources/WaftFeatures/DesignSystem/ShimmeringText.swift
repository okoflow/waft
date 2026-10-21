import SwiftUI

struct ShimmeringText: View {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let text: String
    var color = Color.white

    var body: some View {
        TimelineView(.animation(paused: reducesMotion)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6

            let center = -0.3 + 1.6 * phase

            Text(text)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: color.opacity(0.35), location: max(0, center - 0.2)),
                            .init(color: color.opacity(0.95), location: min(1, max(0, center))),
                            .init(color: color.opacity(0.35), location: min(1, center + 0.2)),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing,
                    ),
                )
        }
    }
}

import SwiftUI

struct ShimmeringText: View {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let text: String
    var color = Color.white

    var body: some View {
        TimelineView(.animation(paused: reducesMotion)) { context in
            let center = Shimmer.center(at: context.date.timeIntervalSinceReferenceDate)

            Text(text)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: color.opacity(0.35), location: max(0, center - Shimmer.width)),
                            .init(color: color.opacity(0.95), location: min(1, max(0, center))),
                            .init(color: color.opacity(0.35), location: min(1, center + Shimmer.width)),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing,
                    ),
                )
        }
    }
}

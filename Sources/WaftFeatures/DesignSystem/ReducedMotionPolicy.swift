import SwiftUI

private struct ReducedMotionPolicy: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    func body(content: Content) -> some View {
        let reducesMotion = reducesMotion

        content.transaction { transaction in
            guard reducesMotion, transaction.animation != nil else { return }

            transaction.animation = Motion.reduced
        }
    }
}

extension View {
    func reducedMotionPolicy() -> some View {
        modifier(ReducedMotionPolicy())
    }
}

import SwiftUI

private struct ReducedMotionPolicy<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let animation: Animation?
    let value: Value

    func body(content: Content) -> some View {
        content.animation(Motion.adapted(animation, reducesMotion: reducesMotion), value: value)
    }
}

extension View {
    func motion(_ animation: Animation?, value: some Equatable) -> some View {
        modifier(ReducedMotionPolicy(animation: animation, value: value))
    }
}

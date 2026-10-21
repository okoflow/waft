import SwiftUI

private struct MotionOffset: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let distance: CGFloat

    func body(content: Content) -> some View {
        content.offset(y: reducesMotion ? 0 : distance)
    }
}

extension View {
    func motionOffset(y distance: CGFloat) -> some View {
        modifier(MotionOffset(distance: distance))
    }
}

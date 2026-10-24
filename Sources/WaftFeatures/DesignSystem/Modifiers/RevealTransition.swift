import SwiftUI

struct RevealTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .motionOffset(y: phase.isIdentity ? 0 : -4)
    }
}

extension Transition where Self == RevealTransition {
    static var reveal: RevealTransition {
        RevealTransition()
    }
}

private struct RowTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    func body(content: Content) -> some View {
        content.transition(AsymmetricTransition(
            insertion: .reveal.animation(Motion.adapted(Motion.layout.delay(0.05), reducesMotion: reducesMotion)),
            removal: .reveal.animation(Motion.adapted(Motion.fade, reducesMotion: reducesMotion)),
        ))
    }
}

extension View {
    func rowTransition() -> some View {
        modifier(RowTransition())
    }
}

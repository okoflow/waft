import SwiftUI

struct RevealTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .offset(y: phase.isIdentity ? 0 : -4)
    }
}

extension Transition where Self == RevealTransition {
    static var reveal: RevealTransition {
        RevealTransition()
    }
}

extension View {
    func rowTransition() -> some View {
        transition(AsymmetricTransition(
            insertion: .reveal.animation(Motion.layout.delay(0.05)),
            removal: .reveal.animation(Motion.fade),
        ))
    }
}

import SwiftUI

struct HUDView: View {
    private let hud: HUDController

    init(hud: HUDController) {
        self.hud = hud
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            pill
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, HUDPanel.shadowRoom)
        .animation(Motion.layout, value: hud.content)
        .reducedMotionPolicy()
    }

    @ViewBuilder
    private var pill: some View {
        if let content = hud.content {
            HUDPill(content: content, levels: hud.levels)
                .transition(AsymmetricTransition(insertion: PillTransition(), removal: PillTransition().animation(Motion.fade)))
        }
    }
}

private struct PillTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .scaleEffect(phase == .willAppear ? 0.9 : phase == .didDisappear ? 0.96 : 1, anchor: .bottom)
            .offset(y: phase == .willAppear ? 8 : 0)
    }
}

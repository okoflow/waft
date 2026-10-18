import SwiftUI

struct ProButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.prominentControl)
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, Metrics.largeControlPadding)
            .frame(height: Metrics.largeControlHeight)
            .background(.white.opacity(configuration.isPressed ? Palette.pressedOpacity : 1), in: Capsule())
            .motion(configuration.isPressed ? nil : Motion.fade, value: configuration.isPressed)
    }
}

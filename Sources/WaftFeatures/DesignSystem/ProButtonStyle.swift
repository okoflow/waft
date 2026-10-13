import SwiftUI

struct ProButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.prominentControl)
            .foregroundStyle(Palette.proBlue)
            .padding(.horizontal, Metrics.largeControlPadding)
            .frame(height: Metrics.largeControlHeight)
            .background(.white.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
            .animation(configuration.isPressed ? nil : Motion.fade, value: configuration.isPressed)
    }
}

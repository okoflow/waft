import SwiftUI

struct SwapButton: View {
    let model: TranslatorModel

    var body: some View {
        Button(action: model.swapLanguages) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.glyph)
                .foregroundStyle(Palette.secondaryText)
                .frame(width: Metrics.swapButtonSize, height: Metrics.swapButtonSize)
                .background(Palette.window, in: Circle())
                .overlay {
                    Circle().strokeBorder(Palette.fieldBorder, lineWidth: 0.5)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!model.canSwap)
        .opacity(model.canSwap ? 1 : Palette.disabledOpacity)
        .keyboardShortcut("s", modifiers: [.command, .shift])
        .help("Swap languages")
        .accessibilityLabel("Swap languages")
    }
}

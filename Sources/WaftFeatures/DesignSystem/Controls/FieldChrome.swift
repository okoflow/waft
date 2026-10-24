import SwiftUI

struct FieldChrome: ViewModifier {
    let isFocused: Bool
    var cornerRadius = Metrics.controlRadius

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let ringOffset = Metrics.focusRingWidth / 2

        content
            .background(Palette.field, in: shape)
            .overlay {
                shape.strokeBorder(isFocused ? Palette.accent : Palette.fieldBorder, lineWidth: isFocused ? 1 : 0.5)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius + ringOffset, style: .continuous)
                    .stroke(Palette.accent.opacity(isFocused ? 0.25 : 0), lineWidth: Metrics.focusRingWidth)
                    .padding(-ringOffset)
            }
            .motion(Motion.fade, value: isFocused)
    }
}

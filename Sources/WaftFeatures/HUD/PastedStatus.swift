import SwiftUI

struct PastedStatus: View {
    let message: HUDMessage
    let hasCopied: Bool

    private var text: LocalizedStringKey {
        guard !hasCopied else { return "Copied" }
        guard message.detail == nil else { return "Without AI" }

        return "Pasted"
    }

    private var style: AnyShapeStyle {
        guard !hasCopied, message.detail != nil else { return AnyShapeStyle(.secondary) }

        return AnyShapeStyle(Palette.warning)
    }

    var body: some View {
        Text(text)
            .font(.hudCaption)
            .foregroundStyle(style)
    }
}

import SwiftUI

struct PastedStatus: View {
    let message: HUDMessage
    let hasCopied: Bool

    private var deliveredText: LocalizedStringKey {
        guard message.detail == nil else { return "Without AI" }

        return "Pasted"
    }

    private var text: LocalizedStringKey {
        guard !hasCopied else { return "Copied" }

        return deliveredText
    }

    private var style: AnyShapeStyle {
        guard !hasCopied, message.detail != nil else { return AnyShapeStyle(.secondary) }

        return AnyShapeStyle(Palette.warning)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Text(deliveredText)
                .hidden()

            Text("Copied")
                .hidden()

            Text(text)
                .foregroundStyle(style)
        }
        .font(.hudCaption)
    }
}

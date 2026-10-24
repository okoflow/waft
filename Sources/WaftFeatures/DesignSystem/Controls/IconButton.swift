import SwiftUI

struct IconButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let symbolName: String
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.glyph)
                .foregroundStyle(Palette.secondaryText)
                .opacity(isEnabled ? 1 : Palette.disabledOpacity)
                .frame(width: Metrics.controlHeight, height: Metrics.controlHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

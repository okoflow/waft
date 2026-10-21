import SwiftUI

struct LinkRow: View {
    let title: LocalizedStringKey
    var detail: String?
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: Metrics.controlSpacing) {
                Text(title)
                    .foregroundStyle(.primary)

                Spacer(minLength: Metrics.rowSpacing)

                if let detail {
                    Text(detail)
                        .foregroundStyle(Palette.secondaryText)
                }

                Image(systemName: "arrow.up.forward")
                    .font(.glyph)
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
            }
            .font(.rowTitle)
            .settingsRowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

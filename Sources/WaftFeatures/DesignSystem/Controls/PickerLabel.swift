import SwiftUI

struct PickerLabel: View {
    let title: String
    let font: Font

    var body: some View {
        HStack(spacing: Metrics.inlineSpacing) {
            Text(title)
                .font(font)
                .foregroundStyle(.primary)

            Image(systemName: "chevron.up.chevron.down")
                .font(.menuChevron)
                .foregroundStyle(Palette.secondaryText)
                .frame(width: 18, height: 18)
                .background(Palette.control, in: Circle())
                .accessibilityHidden(true)
        }
        .widenedHitTarget()
    }
}

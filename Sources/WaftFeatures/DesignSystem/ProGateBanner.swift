import SwiftUI

struct ProGateBanner: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let showPro: () -> Void

    var body: some View {
        let shape = RoundedRectangle.card

        HStack(spacing: Metrics.rowSpacing) {
            WaftPlusMark(size: Metrics.tileSize)

            VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                Text(title)
                    .font(.cardTitle)

                Text(detail)
                    .detailText()
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button("Unlock Waft+…", action: showPro)
                .buttonStyle(PushButtonStyle(isProminent: true))
        }
        .padding(Metrics.rowPadding)
        .background(Palette.plusTint, in: shape)
    }
}

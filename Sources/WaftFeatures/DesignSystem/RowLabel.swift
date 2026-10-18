import SwiftUI

struct RowLabel: View {
    let title: LocalizedStringKey
    var description: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
            Text(title)
                .font(.rowTitle)

            if let description {
                Text(description)
                    .font(.rowDetail)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

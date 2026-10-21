import SwiftUI

struct RowLabel: View {
    let title: LocalizedStringKey
    var description: LocalizedStringKey?
    var isTitleAccessible = true

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
            Text(title)
                .font(.rowTitle)
                .accessibilityHidden(!isTitleAccessible)

            if let description {
                Text(description)
                    .detailText()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

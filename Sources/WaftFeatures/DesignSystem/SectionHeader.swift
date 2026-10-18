import SwiftUI

struct SectionHeader: View {
    let title: LocalizedStringKey?
    var subtitle: LocalizedStringKey?
    var isPro = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
            if let title {
                HStack(spacing: Metrics.inlineSpacing) {
                    Text(title)
                        .font(.sectionTitle)
                        .accessibilityAddTraits(.isHeader)

                    if isPro {
                        ProBadge()
                    }
                }
            }

            if let subtitle {
                Text(subtitle)
                    .detailText()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

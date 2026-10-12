import SwiftUI

struct RowLabel: View {
    let title: LocalizedStringKey
    var description: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.rowTitle)

            if let description {
                Text(description)
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

import SwiftUI
import WaftCore

struct AboutSettingsPane: View {
    private static let website = URL(literal: "https://waft.okoflow.com")
    private static let repository = URL(literal: "https://github.com/okoflow/waft")
    private static let license = URL(literal: "https://github.com/okoflow/waft/blob/main/LICENSE")
    private static let copyright = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String

    var body: some View {
        VStack(spacing: 4) {
            AppIcon(size: Metrics.pageIconSize)

            Text("Waft")
                .font(.heroTitle)
                .accessibilityAddTraits(.isHeader)

            Text(AppVersion.title)
                .font(.rowTitle)
                .foregroundStyle(Palette.secondaryText)

            Text("On-device dictation for macOS with AI cleanup.")
                .font(.rowTitle)
                .multilineTextAlignment(.center)
                .padding(.top, Metrics.controlSpacing)
        }
        .frame(maxWidth: .infinity)

        SettingsSection {
            LinkRow(title: "Website", detail: "waft.okoflow.com", url: Self.website)
            RowDivider()
            LinkRow(title: "Source code", detail: "github.com/okoflow/waft", url: Self.repository)
            RowDivider()
            LinkRow(title: "License", detail: "GPL-3.0-only", url: Self.license)
        }

        if let copyright = Self.copyright {
            Text(verbatim: copyright)
                .detailText()
                .frame(maxWidth: .infinity)
        }
    }
}

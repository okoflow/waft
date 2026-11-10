import SwiftUI

struct SettingsGroup<Content: View, Accessory: View>: View {
    private let title: LocalizedStringKey?
    private let subtitle: LocalizedStringKey?
    private let needsWaftPlus: Bool
    private let accessory: Accessory?
    private let content: Content

    init(
        title: LocalizedStringKey?,
        subtitle: LocalizedStringKey?,
        needsWaftPlus: Bool,
        accessory: Accessory?,
        @ViewBuilder content: () -> Content,
    ) {
        self.title = title
        self.subtitle = subtitle
        self.needsWaftPlus = needsWaftPlus
        self.accessory = accessory
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.groupSpacing) {
            if let title {
                header(title)
            }

            content
        }
    }

    private func header(_ title: LocalizedStringKey) -> some View {
        HStack(spacing: Metrics.rowSpacing) {
            VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                HStack(spacing: Metrics.inlineSpacing) {
                    Text(title)
                        .font(.sectionTitle)
                        .accessibilityAddTraits(.isHeader)

                    if needsWaftPlus {
                        ProBadge()
                    }
                }

                if let subtitle {
                    Text(subtitle)
                        .detailText()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            accessory
        }
        .padding(.horizontal, Metrics.rowPadding)
    }
}

extension SettingsGroup where Accessory == EmptyView {
    init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content,
    ) {
        self.init(title: title, subtitle: subtitle, needsWaftPlus: false, accessory: nil, content: content)
    }
}

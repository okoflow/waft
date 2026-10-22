import SwiftUI

struct SettingsGroup<Content: View, Accessory: View>: View {
    private let title: LocalizedStringKey?
    private let subtitle: LocalizedStringKey?
    private let needsWaftPlus: Bool
    private let accessory: Accessory?
    private let content: Content

    private var hasHeader: Bool {
        guard title == nil, subtitle == nil else { return true }

        return accessory != nil
    }

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
            if hasHeader {
                header
            }

            content
        }
    }

    private var header: some View {
        HStack(spacing: Metrics.rowSpacing) {
            VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                if let title {
                    HStack(spacing: Metrics.inlineSpacing) {
                        Text(title)
                            .font(.sectionTitle)
                            .accessibilityAddTraits(.isHeader)

                        if needsWaftPlus {
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
        needsWaftPlus: Bool = false,
        @ViewBuilder content: () -> Content,
    ) {
        self.init(title: title, subtitle: subtitle, needsWaftPlus: needsWaftPlus, accessory: nil, content: content)
    }
}

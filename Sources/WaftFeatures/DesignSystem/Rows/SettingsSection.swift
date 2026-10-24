import SwiftUI

struct SettingsSection<Content: View, Accessory: View, Footer: View>: View {
    private let title: LocalizedStringKey?
    private let subtitle: LocalizedStringKey?
    private let needsWaftPlus: Bool
    private let content: Content
    private let accessory: Accessory?
    private let footer: Footer?

    init(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder footer: () -> Footer,
    ) {
        self.init(title: title, subtitle: nil, needsWaftPlus: false, content: content(), accessory: accessory(), footer: footer())
    }

    private init(
        title: LocalizedStringKey?,
        subtitle: LocalizedStringKey?,
        needsWaftPlus: Bool,
        content: Content,
        accessory: Accessory?,
        footer: Footer?,
    ) {
        self.title = title
        self.subtitle = subtitle
        self.needsWaftPlus = needsWaftPlus
        self.content = content
        self.accessory = accessory
        self.footer = footer
    }

    var body: some View {
        SettingsGroup(title: title, subtitle: subtitle, needsWaftPlus: needsWaftPlus, accessory: accessory) {
            SettingsCard {
                content
            }

            if let footer {
                HStack(spacing: Metrics.controlSpacing) {
                    Spacer(minLength: 0)

                    footer
                }
            }
        }
    }
}

extension SettingsSection where Accessory == EmptyView, Footer == EmptyView {
    init(
        _ title: LocalizedStringKey? = nil,
        subtitle: LocalizedStringKey? = nil,
        needsWaftPlus: Bool = false,
        @ViewBuilder content: () -> Content,
    ) {
        self.init(title: title, subtitle: subtitle, needsWaftPlus: needsWaftPlus, content: content(), accessory: nil, footer: nil)
    }
}

extension SettingsSection where Accessory == EmptyView {
    init(
        _ title: LocalizedStringKey?,
        subtitle: LocalizedStringKey? = nil,
        needsWaftPlus: Bool = false,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer,
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            needsWaftPlus: needsWaftPlus,
            content: content(),
            accessory: nil,
            footer: footer(),
        )
    }
}

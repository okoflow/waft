import SwiftUI

struct SettingsGroup<Content: View, Accessory: View>: View {
    private let title: LocalizedStringKey?
    private let subtitle: LocalizedStringKey?
    private let isPro: Bool
    private let accessory: Accessory?
    private let content: Content

    private var hasHeader: Bool {
        title != nil || subtitle != nil || accessory != nil
    }

    init(
        title: LocalizedStringKey?,
        subtitle: LocalizedStringKey?,
        isPro: Bool,
        accessory: Accessory?,
        @ViewBuilder content: () -> Content,
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isPro = isPro
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
            SectionHeader(title: title, subtitle: subtitle, isPro: isPro)

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
        isPro: Bool = false,
        @ViewBuilder content: () -> Content,
    ) {
        self.init(title: title, subtitle: subtitle, isPro: isPro, accessory: nil, content: content)
    }
}

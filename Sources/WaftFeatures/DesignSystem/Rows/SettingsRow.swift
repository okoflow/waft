import SwiftUI

struct SettingsRow<Accessory: View>: View {
    private let title: LocalizedStringKey
    private let description: LocalizedStringKey?
    private let labelsAccessory: Bool
    private let accessory: Accessory

    init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        labelsAccessory: Bool = false,
        @ViewBuilder accessory: () -> Accessory,
    ) {
        self.title = title
        self.description = description
        self.labelsAccessory = labelsAccessory
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: Metrics.rowSpacing) {
            RowLabel(title: title, description: description, isTitleAccessible: !labelsAccessory)

            Spacer(minLength: 0)

            HStack(spacing: Metrics.controlSpacing) {
                accessory
            }
        }
        .settingsRowPadding()
    }
}

extension View {
    func settingsRowPadding() -> some View {
        padding(Metrics.rowPadding)
            .frame(minHeight: Metrics.rowMinimumHeight)
    }
}

import SwiftUI

struct TileRow<Accessory: View>: View {
    private let symbolName: String
    private let tint: TileTint
    private let title: LocalizedStringKey
    private let detail: LocalizedStringKey
    private let accessory: Accessory

    init(
        symbolName: String,
        tint: TileTint,
        title: LocalizedStringKey,
        detail: LocalizedStringKey,
        @ViewBuilder accessory: () -> Accessory,
    ) {
        self.symbolName = symbolName
        self.tint = tint
        self.title = title
        self.detail = detail
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: Metrics.iconLabelSpacing) {
            IconTile(symbolName: symbolName, tint: tint, size: Metrics.rowTileSize)

            RowLabel(title: title, description: detail)

            Spacer(minLength: 0)

            accessory
        }
        .settingsRowPadding()
    }
}

extension TileRow where Accessory == EmptyView {
    init(symbolName: String, tint: TileTint, title: LocalizedStringKey, detail: LocalizedStringKey) {
        self.init(symbolName: symbolName, tint: tint, title: title, detail: detail) {
            EmptyView()
        }
    }
}

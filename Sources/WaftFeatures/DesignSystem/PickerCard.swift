import SwiftUI

struct PickerCard<Preview: View>: View {
    private let title: LocalizedStringKey
    private let detail: LocalizedStringKey
    private let isSelected: Bool
    private let isPro: Bool
    private let action: () -> Void
    private let preview: Preview

    init(
        _ title: LocalizedStringKey,
        detail: LocalizedStringKey,
        isSelected: Bool,
        isPro: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder preview: () -> Preview,
    ) {
        self.title = title
        self.detail = detail
        self.isSelected = isSelected
        self.isPro = isPro
        self.action = action
        self.preview = preview()
    }

    var body: some View {
        let shape = RoundedRectangle.card

        Button(action: action) {
            VStack(alignment: .leading, spacing: Metrics.pickerCardSpacing) {
                preview
                    .frame(maxWidth: .infinity)
                    .frame(height: Metrics.pickerPreviewHeight)
                    .background(Palette.field, in: RoundedRectangle(cornerRadius: Metrics.editorRadius, style: .continuous))

                VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                    HStack(spacing: Metrics.inlineSpacing) {
                        Text(title)
                            .font(.cardTitle)

                        if isPro {
                            ProBadge()
                        }
                    }

                    Text(detail)
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                }
                .padding(.horizontal, 2)
            }
            .padding(Metrics.pickerCardPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Palette.card, in: shape)
            .overlay {
                shape.strokeBorder(isSelected ? Palette.accent : Palette.cardBorder, lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .motion(Motion.feedback, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

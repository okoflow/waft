import SwiftUI

struct SearchField: View {
    @Binding private var text: String
    @FocusState private var isFocused: Bool

    private let prompt: LocalizedStringKey

    init(_ prompt: LocalizedStringKey, text: Binding<String>) {
        self.prompt = prompt
        _text = text
    }

    var body: some View {
        HStack(spacing: Metrics.inlineSpacing) {
            Image(systemName: "magnifyingglass")
                .font(.glyph)
                .foregroundStyle(Palette.secondaryText)
                .accessibilityHidden(true)

            TextField(prompt, text: $text, prompt: Text(prompt))
                .textFieldStyle(.plain)
                .font(.control)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .widenedHitTarget()
                }
                .buttonStyle(.plain)
                .help("Clear")
                .accessibilityLabel("Clear the search")
            }
        }
        .padding(.horizontal, Metrics.fieldPadding)
        .frame(height: Metrics.controlHeight)
        .modifier(FieldChrome(isFocused: isFocused))
    }
}

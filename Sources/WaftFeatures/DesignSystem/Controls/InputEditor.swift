import SwiftUI

struct InputEditor: View {
    private static let lineFragmentPadding: CGFloat = 5
    private static let verticalPadding: CGFloat = 6

    @Binding private var text: String
    @FocusState private var isFocused: Bool

    init(text: Binding<String>) {
        _text = text
    }

    var body: some View {
        TextEditor(text: $text)
            .font(.editor)
            .scrollContentBackground(.hidden)
            .focused($isFocused)
            .contentDirection(of: text)
            .padding(.horizontal, Metrics.fieldPadding - Self.lineFragmentPadding)
            .padding(.vertical, Self.verticalPadding)
            .modifier(FieldChrome(isFocused: isFocused))
    }
}

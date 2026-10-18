import SwiftUI

struct InputEditor: View {
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
            .padding(6)
            .modifier(FieldChrome(isFocused: isFocused, cornerRadius: Metrics.editorRadius))
    }
}

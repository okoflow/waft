import SwiftUI

struct InputField: View {
    @Binding private var text: String
    @FocusState private var isFocused: Bool

    private let label: LocalizedStringKey
    private let prompt: LocalizedStringKey
    private let isSecure: Bool

    init(_ label: LocalizedStringKey, prompt: LocalizedStringKey, text: Binding<String>, isSecure: Bool = false) {
        self.label = label
        self.prompt = prompt
        _text = text
        self.isSecure = isSecure
    }

    var body: some View {
        field
            .textFieldStyle(.plain)
            .font(.control)
            .focused($isFocused)
            .padding(.horizontal, Metrics.fieldPadding)
            .frame(height: Metrics.controlHeight)
            .modifier(FieldChrome(isFocused: isFocused))
    }

    @ViewBuilder
    private var field: some View {
        if isSecure {
            SecureField(label, text: $text, prompt: Text(prompt))
        } else {
            TextField(label, text: $text, prompt: Text(prompt))
                .contentDirection(of: text)
        }
    }
}

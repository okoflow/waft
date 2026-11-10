import SwiftUI

struct MenuPicker<Value: Hashable, Options: View>: View {
    @Binding private var selection: Value

    private let title: LocalizedStringKey
    private let current: String
    private let options: Options

    init(_ title: LocalizedStringKey, selection: Binding<Value>, current: String, @ViewBuilder options: () -> Options) {
        self.title = title
        _selection = selection
        self.current = current
        self.options = options()
    }

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                options
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } label: {
            PickerLabel(title: current, font: .control)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel(title)
        .accessibilityValue(current)
    }
}

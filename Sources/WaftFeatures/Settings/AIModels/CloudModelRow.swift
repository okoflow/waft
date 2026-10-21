import SwiftUI
import WaftCore

struct CloudModelRow: View {
    @Binding var model: CloudModel

    let provider: CloudProvider

    var body: some View {
        PickerRow("Model", selection: $model, current: provider.name(of: model), description: .verbatim(model.summary)) {
            ForEach(CloudModel.allCases, id: \.self) { model in
                Text(verbatim: provider.name(of: model)).tag(model)
            }
        }
    }
}

import SwiftUI
import WaftCore

struct ProMenuItem: View {
    let pro: ProModel
    let showPro: () -> Void

    var body: some View {
        switch pro.access.status {
        case .licensed, .beta:
            EmptyView()

        case .trial, .expired:
            Button("Unlock Waft+…", action: showPro)
        }
    }
}

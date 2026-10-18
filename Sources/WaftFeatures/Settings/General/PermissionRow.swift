import SwiftUI
import WaftCore

struct PermissionRow: View {
    let permission: Permission
    let monitor: PermissionMonitor
    var description: LocalizedStringKey?
    var offersRequest = true

    private var isGranted: Bool {
        monitor.status(of: permission).isGranted
    }

    var body: some View {
        SettingsRow(.verbatim(permission.title), description: description) {
            HStack(spacing: Metrics.inlineSpacing) {
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.success)
                        .modifier(CheckmarkAppear())
                        .accessibilityHidden(true)

                    Text("Allowed")
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                } else if offersRequest {
                    Button("Allow…") {
                        Task { await monitor.request(permission) }
                    }
                    .transition(.opacity)
                } else {
                    Text("Not allowed yet")
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }
            .font(.rowTitle)
            .motion(Motion.feedback, value: isGranted)
        }
    }
}

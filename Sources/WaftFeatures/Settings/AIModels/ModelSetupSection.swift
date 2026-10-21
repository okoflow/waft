import SwiftUI
import WaftCore

struct ModelSetupSection<Content: View>: View {
    private let title: LocalizedStringKey
    private let subtitle: LocalizedStringKey?
    private let setupNote: LocalizedStringKey?
    private let state: SettingsWindowState
    private let content: Content

    init(
        _ title: LocalizedStringKey,
        setup: AIModelSetup,
        settings: SettingsModel,
        apiKeys: PerProvider<APIKeyModel>,
        state: SettingsWindowState,
        subtitle: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content,
    ) {
        self.title = title
        self.subtitle = subtitle
        setupNote = setup.missingSetup(in: settings, apiKeys: apiKeys)
        self.state = state
        self.content = content()
    }

    var body: some View {
        if let setupNote {
            SettingsSection(title, subtitle: subtitle) {
                content
            } footer: {
                Text(setupNote)
                    .detailText()

                Button("Set Up…") { state.selection = .aiModels }
            }
        } else {
            SettingsSection(title, subtitle: subtitle) {
                content
            }
        }
    }
}

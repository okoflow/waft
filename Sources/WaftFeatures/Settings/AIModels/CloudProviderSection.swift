import SwiftUI
import WaftCore

struct CloudProviderSection: View {
    @Bindable var settings: SettingsModel

    let provider: CloudProvider
    let apiKey: APIKeyModel

    var body: some View {
        SettingsSection(
            .verbatim(provider.title),
            subtitle: "Uses your own API key. Only the text goes to \(provider.company), never the audio.",
        ) {
            CloudModelRow(model: $settings.settings.cloudModels[provider], provider: provider)
            RowDivider()
            APIKeyRows(apiKey: apiKey, provider: provider)
            RowDivider()
            LinkRow(title: "Get an API key", url: provider.consoleURL)
        }
        .motion(Motion.layout, value: apiKey.isSet)
    }
}

private struct APIKeyRows: View {
    @Bindable var apiKey: APIKeyModel

    let provider: CloudProvider

    private var prompt: LocalizedStringKey {
        apiKey.isSet ? "Replace the key" : .verbatim(provider.keyPlaceholder)
    }

    var body: some View {
        if apiKey.isSet {
            SettingsRow("Key saved", description: "Kept in the Keychain.") {
                Button("Remove…", role: .destructive, action: confirmRemoval)
            }
            .rowTransition()
            RowDivider()
                .rowTransition()
        }

        HStack(spacing: Metrics.controlSpacing) {
            InputField("API key", prompt: prompt, text: $apiKey.draft, isSecure: true)

            Button("Save") { apiKey.saveDraft() }
                .disabled(!apiKey.canSaveDraft)
        }
        .settingsRowPadding()
    }

    private func confirmRemoval() {
        let confirmation = Confirmation(
            message: String(localized: "Remove the API key?"),
            detail: String(localized: "Waft deletes it from the Keychain. The AI modes use Light until you add a key."),
            action: String(localized: "Remove Key"),
        )

        if confirmation.ask() {
            apiKey.remove()
        }
    }
}

import SwiftUI
import WaftCore

struct CloudProviderSection: View {
    let provider: CloudProvider
    let apiKey: APIKeyModel

    var body: some View {
        SettingsSection(
            .verbatim(provider.title),
            subtitle: "Uses your own API key. Only the text goes to \(provider.company), never the audio.",
        ) {
            APIKeyRows(apiKey: apiKey, provider: provider)
            RowDivider()
            LinkRow(title: "Get an API key", url: provider.consoleURL)
        }
        .animation(Motion.layout, value: apiKey.isSet)
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
                Button("Remove", role: .destructive) { apiKey.remove() }
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
}

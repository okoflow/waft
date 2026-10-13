import SwiftUI
import WaftCore

struct LocalServerSection: View {
    @Bindable var settings: SettingsModel

    let localModels: LocalModelsModel

    private var status: LocalizedStringKey {
        switch localModels.serverState {
        case .unknown: "Not checked yet"
        case .checking: "Checking…"
        case .running: localModels.serverModels.isEmpty ? "Running, but no models are loaded" : "Running"
        case .notRunning: "Not running at this address"
        }
    }

    private var modelTitle: String {
        settings.settings.localServer.model.isEmpty ? String(localized: "Choose") : settings.settings.localServer.model
    }

    var body: some View {
        SettingsSection(
            "Local server",
            subtitle: "Ollama, LM Studio, llama.cpp, MLX, or Jan on this Mac; the text never leaves it.",
        ) {
            HStack(spacing: Metrics.controlSpacing) {
                InputField(
                    "Server address",
                    prompt: .verbatim("http://localhost:11434/v1"),
                    text: $settings.settings.localServer.baseURL,
                )
                .onSubmit(localModels.refresh)

                Button("Detect", action: localModels.detect)
            }
            .settingsRowPadding()

            RowDivider()
            SettingsRow("Model", description: status) {
                if localModels.serverModels.isEmpty {
                    Button("Check", action: localModels.refresh)
                } else {
                    MenuPicker("Model", selection: $settings.settings.localServer.model, current: modelTitle) {
                        ForEach(localModels.serverModels, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
            }
        }
        .onAppear(perform: localModels.refresh)
    }
}

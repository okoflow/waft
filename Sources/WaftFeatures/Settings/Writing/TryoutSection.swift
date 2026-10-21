import SwiftUI
import WaftCore

struct TryoutSection: View {
    @Bindable var tryout: TryoutModel

    let sampleTitle: LocalizedStringKey
    let samplePrompt: LocalizedStringKey
    let run: () -> Void

    private var canRun: Bool {
        guard tryout.phase != .running else { return false }

        return !tryout.sample.isBlank
    }

    var body: some View {
        SettingsSection("Try it") {
            VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                Text(sampleTitle)
                    .detailText()

                InputField(sampleTitle, prompt: samplePrompt, text: $tryout.sample)
            }
            .settingsRowPadding()

            RowDivider()

            HStack(spacing: Metrics.rowSpacing) {
                VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                    Text("Waft writes")
                        .detailText()

                    result
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(tryout.phase == .idle ? "Run" : "Run Again", action: run)
                    .disabled(!canRun)
            }
            .settingsRowPadding()
        }
    }

    @ViewBuilder
    private var result: some View {
        switch tryout.phase {
        case .idle:
            Text("Run it to see what Waft writes.")
                .font(.rowTitle)
                .foregroundStyle(.tertiary)

        case .running:
            ProgressView()
                .controlSize(.small)

        case let .finished(text, note):
            if !text.isEmpty {
                Text(text)
                    .font(.rowTitle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentDirection(of: text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let note {
                Text(note)
                    .font(.rowDetail)
                    .foregroundStyle(Palette.warning)
            }
        }
    }
}

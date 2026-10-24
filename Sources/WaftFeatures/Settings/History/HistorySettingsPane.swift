import SwiftUI
import WaftCore

struct HistorySettingsPane: View {
    @Bindable var settings: SettingsModel
    @Bindable var history: HistoryModel

    let state: SettingsWindowState

    var body: some View {
        SettingsSection("Saving") {
            ToggleRow("Keep history", isOn: $settings.settings.keepsHistory, description: "Saved only on this Mac.")

            if settings.settings.keepsHistory {
                RowDivider()
                    .rowTransition()
                PickerRow(
                    "Keep dictations for",
                    selection: $settings.settings.historyRetention,
                    current: settings.settings.historyRetention.title,
                ) {
                    ForEach(HistoryRetention.allCases, id: \.self) { retention in
                        Text(retention.title).tag(retention)
                    }
                }
                .rowTransition()
                RowDivider()
                    .rowTransition()
                PickerRow(
                    "Keep at most",
                    selection: $settings.settings.historyLimit,
                    current: Self.limitTitle(settings.settings.historyLimit),
                ) {
                    ForEach(DictationHistory.limits, id: \.self) { limit in
                        Text(Self.limitTitle(limit)).tag(limit)
                    }
                }
                .rowTransition()
            }
        }
        .motion(Motion.layout, value: settings.settings.keepsHistory)

        let page = history.currentPage

        SettingsSection("Dictations") {
            if page.entries.isEmpty {
                EmptyRow(history.emptyText)
            }

            DividedForEach(page.entries, id: \.date) { entry in
                HistoryRow(
                    entry: entry,
                    modeTitle: settings.settings.title(of: entry.mode),
                    appName: entry.app.map(InstalledApp.name(of:)),
                    isCopied: state.copiedEntries.isShowing(entry.date),
                    copy: {
                        history.copy(entry)
                        state.copiedEntries.show(entry.date)
                    },
                    copyTranscript: { history.copyTranscript(of: entry) },
                )
            }

            if page.isPaged {
                RowDivider()
                PagerRow(page: page, previous: history.showPreviousPage, next: history.showNextPage)
            }
        } accessory: {
            SearchField("Search", text: $history.searchText)
                .frame(width: 200)
        } footer: {
            Button("Clear History…", role: .destructive, action: confirmClear)
                .disabled(!history.canClear)
        }
    }

    private static func limitTitle(_ limit: Int) -> String {
        String(localized: "\(limit.formatted()) dictations")
    }

    private func confirmClear() {
        let confirmation = Confirmation(
            message: String(localized: "Clear the dictation history?"),
            detail: String(localized: "This deletes every saved dictation. It can't be undone."),
            action: String(localized: "Clear History"),
        )

        guard confirmation.ask() else { return }

        history.removeAll()
    }
}

private struct HistoryRow: View {
    let entry: DictationHistory.Entry
    let modeTitle: String
    let appName: String?
    let isCopied: Bool
    let copy: () -> Void
    let copyTranscript: () -> Void

    private var details: String {
        let time = entry.date.formatted(date: .abbreviated, time: .shortened)

        return [time, modeTitle, appName].compactMap(\.self).map { "\u{2068}\($0)\u{2069}" }.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: Metrics.rowSpacing) {
            VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                Text(entry.text)
                    .font(.rowTitle)
                    .lineLimit(3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentDirection(of: entry.text)

                Text(details)
                    .detailText()
            }

            Spacer(minLength: 0)

            CopyButton(isCopied: isCopied, action: copy)
        }
        .settingsRowPadding()
        .contextMenu {
            Button("Copy", action: copy)

            if entry.transcript != nil {
                Button("Copy Original Transcript", action: copyTranscript)
            }
        }
    }
}

private struct PagerRow: View {
    let page: HistoryModel.Page
    let previous: () -> Void
    let next: () -> Void

    private var range: String {
        let first = page.firstPosition.formatted()
        let last = page.lastPosition.formatted()

        return String(localized: "\(first)–\(last) of \(page.total.formatted())")
    }

    var body: some View {
        HStack(spacing: Metrics.controlSpacing) {
            Text(range)
                .detailText()
                .monospacedDigit()

            Spacer(minLength: 0)

            Button(action: previous) {
                Image(systemName: "chevron.backward")
            }
            .disabled(!page.hasPrevious)
            .help("Previous page")
            .accessibilityLabel("Previous page")

            Button(action: next) {
                Image(systemName: "chevron.forward")
            }
            .disabled(!page.hasNext)
            .help("Next page")
            .accessibilityLabel("Next page")
        }
        .settingsRowPadding()
    }
}

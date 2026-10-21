import SwiftUI
import WaftCore

struct LanguagePicker: View {
    @Binding var selection: Language?

    @Bindable var state: LanguagePickerState

    let title: String
    let label: LocalizedStringKey
    let recent: [Language]
    let detectsLanguage: Bool

    var body: some View {
        Button {
            state.isPresented = true
        } label: {
            HStack(spacing: Metrics.inlineSpacing) {
                Text(title)
                    .font(.cardTitle)
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.menuChevron)
                    .foregroundStyle(Palette.secondaryText)
                    .frame(width: 18, height: 18)
                    .background(Palette.control, in: Circle())
            }
            .widenedHitTarget()
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(label)
        .accessibilityValue(title)
        .popover(isPresented: $state.isPresented, arrowEdge: .bottom) {
            LanguageList(state: state, selection: selection, recent: recent, detectsLanguage: detectsLanguage) { language in
                selection = language
                state.isPresented = false
            }
        }
    }
}

private struct LanguageList: View {
    @Bindable var state: LanguagePickerState

    let selection: Language?
    let recent: [Language]
    let detectsLanguage: Bool
    let choose: (Language?) -> Void

    private var matches: [Language] {
        let query = state.query

        guard !query.isBlank else { return Language.allByDisplayName }

        return Language.allByDisplayName.filter { language in
            [language.displayName, language.nativeName, language.name].contains { $0.localizedStandardContains(query) }
        }
    }

    var body: some View {
        VStack(spacing: Metrics.controlSpacing) {
            SearchField("Search languages", text: $state.query)
                .onSubmit(chooseFirstMatch)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if state.query.isBlank {
                        if detectsLanguage {
                            LanguageRow(
                                id: "detect",
                                title: String(localized: "Detect language"),
                                detail: nil,
                                isSelected: selection == nil,
                                state: state,
                            ) {
                                choose(nil)
                            }
                        }

                        if !recent.isEmpty {
                            ListHeader("Recent")

                            rows(for: recent)
                        }

                        ListHeader("All languages")
                    }

                    rows(for: matches)

                    if matches.isEmpty {
                        Text("No languages found")
                            .detailText()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Metrics.rowPadding)
                    }
                }
            }
        }
        .padding(Metrics.controlSpacing)
        .frame(width: Metrics.languageListWidth, height: Metrics.languageListHeight)
    }

    private func rows(for languages: [Language]) -> some View {
        ForEach(languages, id: \.self) { language in
            LanguageRow(
                id: language.rawValue,
                title: language.displayName,
                detail: language.nativeName == language.displayName ? nil : language.nativeName,
                isSelected: selection == language,
                state: state,
            ) {
                choose(language)
            }
        }
    }

    private func chooseFirstMatch() {
        guard !state.query.isBlank, let language = matches.first else { return }

        choose(language)
    }
}

private struct ListHeader: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.sidebarGroup)
            .foregroundStyle(Palette.secondaryText)
            .padding(.horizontal, Metrics.controlSpacing)
            .padding(.top, Metrics.controlSpacing)
            .padding(.bottom, Metrics.labelSpacing)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct LanguageRow: View {
    let id: String
    let title: String
    let detail: String?
    let isSelected: Bool
    let state: LanguagePickerState
    let action: () -> Void

    private var isHovered: Bool {
        state.hoveredRow == id
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Metrics.inlineSpacing) {
                Image(systemName: "checkmark")
                    .font(.glyph)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.control)

                Spacer(minLength: Metrics.controlSpacing)

                if let detail {
                    Text(detail)
                        .font(.control)
                        .foregroundStyle(isHovered ? .white.opacity(0.75) : Palette.secondaryText)
                }
            }
            .foregroundStyle(isHovered ? .white : .primary)
            .padding(.horizontal, Metrics.controlSpacing)
            .frame(height: Metrics.controlHeight + 4)
            .background(isHovered ? Palette.accent : .clear, in: RoundedRectangle(cornerRadius: Metrics.controlRadius))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { state.hover(id, $0) }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

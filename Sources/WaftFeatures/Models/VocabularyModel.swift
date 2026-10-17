import Foundation
import Observation
import WaftCore

@Observable
final class VocabularyModel {
    struct TermDraft: Identifiable {
        let id = UUID()
        var term: String
        var spokenForms: String
    }

    struct SnippetDraft: Identifiable {
        let id = UUID()
        var trigger: String
        var text: String
    }

    var terms: [TermDraft] = [] {
        didSet { draftsDidChange() }
    }

    var snippets: [SnippetDraft] = [] {
        didSet { draftsDidChange() }
    }

    @ObservationIgnored private var current = Vocabulary.empty
    @ObservationIgnored private var isLoadingDrafts = false

    private let store: any ValueStore<Vocabulary>
    private let fileURL: URL
    private let urlOpener: any URLOpener

    init(store: any ValueStore<Vocabulary>, fileURL: URL, urlOpener: any URLOpener) {
        self.store = store
        self.fileURL = fileURL
        self.urlOpener = urlOpener

        loadDrafts(from: store.read(default: .empty))
    }

    private static func vocabulary(from terms: [TermDraft], _ snippets: [SnippetDraft]) -> Vocabulary {
        let validTerms = terms.compactMap { draft -> Vocabulary.Term? in
            let term = draft.term.trimmingCharacters(in: .whitespaces)
            guard !term.isEmpty else { return nil }

            let spoken = draft.spokenForms.split { $0 == "," || $0 == "،" }
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            return Vocabulary.Term(term: term, spoken: spoken)
        }
        let validSnippets = snippets.compactMap { draft -> Vocabulary.Snippet? in
            let trigger = draft.trigger.trimmingCharacters(in: .whitespaces)
            guard !trigger.isEmpty else { return nil }

            return Vocabulary.Snippet(trigger: trigger, text: draft.text)
        }

        return Vocabulary(terms: validTerms, snippets: validSnippets)
    }

    func addTerm() {
        terms.append(TermDraft(term: "", spokenForms: ""))
    }

    func removeTerm(_ id: TermDraft.ID) {
        terms.removeAll { $0.id == id }
    }

    func addSnippet() {
        snippets.append(SnippetDraft(trigger: "", text: ""))
    }

    func removeSnippet(_ id: SnippetDraft.ID) {
        snippets.removeAll { $0.id == id }
    }

    func openInEditor() {
        if !store.exists() {
            store.write(current)
        }

        urlOpener.open(fileURL)
    }

    func revealInFinder() {
        urlOpener.reveal(fileURL)
    }

    func reloadFromDisk() -> Vocabulary {
        if let latest = store.read(), latest != current {
            loadDrafts(from: latest)
        }

        return current
    }

    private func loadDrafts(from vocabulary: Vocabulary) {
        isLoadingDrafts = true
        defer { isLoadingDrafts = false }

        current = vocabulary
        terms = vocabulary.terms.map { TermDraft(term: $0.term, spokenForms: $0.spoken.joined(separator: ", ")) }
        snippets = vocabulary.snippets.map { SnippetDraft(trigger: $0.trigger, text: $0.text) }
    }

    private func draftsDidChange() {
        guard !isLoadingDrafts else { return }

        let edited = Self.vocabulary(from: terms, snippets)
        guard edited != current else { return }

        current = edited
        store.write(edited)
    }
}

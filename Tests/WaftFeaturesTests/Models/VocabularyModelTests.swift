import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct VocabularyModelTests {
    private nonisolated static let stored = Vocabulary(
        terms: [Vocabulary.Term(term: "Okoflow", spoken: ["oko flow", "okay flow"])],
        snippets: [Vocabulary.Snippet(trigger: "my email", text: "ann@example.com")],
    )

    private nonisolated static let edited = Vocabulary(terms: [Vocabulary.Term(term: "Waft", spoken: [])], snippets: [])
    private static let fileURL = URL(filePath: "/tmp/Dictionary.json")

    @Test
    func `loads the stored dictionary into drafts with spoken forms joined by commas`() {
        let vocabulary = model(FakeValueStore(Self.stored))

        #expect(vocabulary.terms.map(\.term) == ["Okoflow"])
        #expect(vocabulary.terms.map(\.spokenForms) == ["oko flow, okay flow"])
        #expect(vocabulary.snippets.map(\.trigger) == ["my email"])
        #expect(vocabulary.snippets.map(\.text) == ["ann@example.com"])
    }

    @Test
    func `saves edited drafts trimmed and without blank terms or snippets`() {
        let store = FakeValueStore<Vocabulary>()
        let vocabulary = model(store)

        vocabulary.addTerm()
        vocabulary.addTerm()
        vocabulary.addSnippet()
        vocabulary.addSnippet()
        vocabulary.terms[0].term = "  Okoflow "
        vocabulary.terms[0].spokenForms = " oko flow, , okay flow "
        vocabulary.snippets[0].trigger = " my email "
        vocabulary.snippets[0].text = "ann@example.com"

        #expect(store.value == Self.stored)
    }

    @Test
    func `splits spoken forms at Latin and Arabic commas`() {
        let store = FakeValueStore<Vocabulary>()
        let vocabulary = model(store)

        vocabulary.addTerm()
        vocabulary.terms[0].term = "Waft"
        vocabulary.terms[0].spokenForms = "واف، وافت, waft"

        #expect(store.value?.terms == [Vocabulary.Term(term: "Waft", spoken: ["واف", "وافت", "waft"])])
    }

    @Test
    func `saves the dictionary without a removed term or snippet`() {
        let store = FakeValueStore(Self.stored)
        let vocabulary = model(store)

        vocabulary.removeTerm(vocabulary.terms[0].id)
        vocabulary.removeSnippet(vocabulary.snippets[0].id)

        #expect(store.value == Vocabulary(terms: [], snippets: []))
    }

    @Test
    func `adds a blank term or snippet without saving it`() {
        let store = FakeValueStore<Vocabulary>()
        let vocabulary = model(store)

        vocabulary.addTerm()
        vocabulary.addSnippet()

        #expect(vocabulary.terms.count == 1)
        #expect(vocabulary.snippets.count == 1)
        #expect(store.value == nil)
    }

    @Test
    func `reloads a dictionary edited on disk into the drafts`() {
        let store = FakeValueStore(Self.stored)
        let vocabulary = model(store)

        store.value = Self.edited

        #expect(vocabulary.reloadFromDisk() == Self.edited)
        #expect(vocabulary.terms.map(\.term) == ["Waft"])
        #expect(vocabulary.snippets.isEmpty)
    }

    @Test
    func `keeps the current dictionary when the file is missing`() {
        let store = FakeValueStore(Self.stored)
        let vocabulary = model(store)

        store.value = nil

        #expect(vocabulary.reloadFromDisk() == Self.stored)
        #expect(vocabulary.terms.map(\.term) == ["Okoflow"])
    }

    @Test
    func `starts with an empty dictionary when the file is unreadable and saves over it with the first edit`() {
        let store = FakeValueStore(Self.stored, isBroken: true)
        let vocabulary = model(store)

        #expect(vocabulary.terms.isEmpty)
        #expect(vocabulary.snippets.isEmpty)
        #expect(vocabulary.reloadFromDisk() == .empty)
        #expect(store.value == Self.stored)

        vocabulary.addTerm()
        vocabulary.terms[0].term = "Waft"

        #expect(store.value == Self.edited)
    }

    @Test
    func `opens an unreadable dictionary file in the editor without writing over it`() {
        let store = FakeValueStore(Self.stored, isBroken: true)
        let urlOpener = FakeURLOpener()
        let vocabulary = VocabularyModel(store: store, fileURL: Self.fileURL, urlOpener: urlOpener)

        vocabulary.openInEditor()

        #expect(store.value == Self.stored)
        #expect(urlOpener.opened == [Self.fileURL])
    }

    @Test
    func `drops an edit that could not be saved when it reloads the dictionary from disk`() {
        let store = FakeValueStore(Self.stored, failsSaving: true)
        let vocabulary = model(store)

        vocabulary.removeSnippet(vocabulary.snippets[0].id)

        #expect(vocabulary.snippets.isEmpty)
        #expect(store.value == Self.stored)
        #expect(vocabulary.reloadFromDisk() == Self.stored)
        #expect(vocabulary.snippets.map(\.trigger) == ["my email"])
    }

    @Test(arguments: [(nil, stored), (edited, edited)] as [(Vocabulary?, Vocabulary)])
    func `writes the dictionary file before opening it in the editor only when it is missing`(
        onDisk: Vocabulary?,
        written: Vocabulary,
    ) {
        let store = FakeValueStore(Self.stored)
        let urlOpener = FakeURLOpener()
        let vocabulary = VocabularyModel(store: store, fileURL: Self.fileURL, urlOpener: urlOpener)
        store.value = onDisk

        vocabulary.openInEditor()

        #expect(store.value == written)
        #expect(urlOpener.opened == [Self.fileURL])
    }

    @Test
    func `reveals the dictionary file in Finder`() {
        let urlOpener = FakeURLOpener()
        let vocabulary = VocabularyModel(store: FakeValueStore(Self.stored), fileURL: Self.fileURL, urlOpener: urlOpener)

        vocabulary.revealInFinder()

        #expect(urlOpener.revealed == [Self.fileURL])
    }

    private func model(_ store: FakeValueStore<Vocabulary>) -> VocabularyModel {
        VocabularyModel(store: store, fileURL: Self.fileURL, urlOpener: FakeURLOpener())
    }
}

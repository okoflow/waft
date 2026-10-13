package struct Vocabulary: Codable, Equatable, Sendable {
    package struct Term: Codable, Equatable, Sendable {
        package var term: String
        package var spoken: [String]

        package init(term: String, spoken: [String]) {
            self.term = term
            self.spoken = spoken
        }

        package init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            term = try container.decode(String.self, forKey: .term)
            spoken = container.decodeValidElements(.spoken)
        }
    }

    package struct Snippet: Codable, Equatable, Sendable {
        package var trigger: String
        package var text: String

        package init(trigger: String, text: String) {
            self.trigger = trigger
            self.text = text
        }
    }

    package static let empty = Vocabulary(terms: [], snippets: [])

    package var terms: [Term]
    package var snippets: [Snippet]

    package var promptTerms: [String] {
        terms.map(\.term)
    }

    package init(terms: [Term], snippets: [Snippet]) {
        self.terms = terms
        self.snippets = snippets
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        terms = container.decodeValidElements(.terms)
        snippets = container.decodeValidElements(.snippets)
    }

    func correcting(_ text: String, language: Language) -> String {
        let replacements = terms.flatMap { term in
            ([term.term] + term.spoken).map { PhraseReplacer.Replacement(phrase: $0, replacement: term.term) }
        }

        return PhraseReplacer(replacements, language: language).apply(to: text)
    }

    func snippet(matchingWhole text: String, language: Language) -> String? {
        let spoken = PhraseReplacer.words(of: text, in: language)
        guard !spoken.isEmpty else { return nil }

        return snippets.first { PhraseReplacer.words(of: $0.trigger, in: language) == spoken }?.text
    }

    func expandingSnippets(in text: String, language: Language) -> String {
        let replacements = snippets.map { PhraseReplacer.Replacement(phrase: $0.trigger, replacement: $0.text) }

        return PhraseReplacer(replacements, language: language).apply(to: text)
    }
}

import Foundation
import Testing
@testable import WaftCore

struct VocabularyTests {
    private static let vocabulary = Vocabulary(
        terms: [
            Vocabulary.Term(term: "Kubernetes", spoken: ["cube or netties", "kubernetis"]),
            Vocabulary.Term(term: "New York", spoken: []),
            Vocabulary.Term(term: "York", spoken: ["yorke"]),
            Vocabulary.Term(term: "C++", spoken: ["c plus plus"]),
            Vocabulary.Term(term: "Kakao", spoken: ["카카오"]),
            Vocabulary.Term(term: "Алёна", spoken: []),
        ],
        snippets: [
            Vocabulary.Snippet(trigger: "my email", text: "me@example.com"),
            Vocabulary.Snippet(trigger: "sign off", text: "Best regards,\nAnn"),
        ],
    )

    @Test(arguments: [
        ("we deploy on cube or netties today", "we deploy on Kubernetes today"),
        ("we deploy on Cube Or Netties today", "we deploy on Kubernetes today"),
        ("Kubernetis, again", "Kubernetes, again"),
        ("kubernetes is spelled right", "Kubernetes is spelled right"),
        ("flying to new york", "flying to New York"),
        ("old yorke", "old York"),
        ("I write c plus plus", "I write C++"),
        ("I write c++ daily", "I write C++ daily"),
        ("алена пришла", "Алёна пришла"),
    ])
    func `corrects terms and their spoken forms`(text: String, expected: String) {
        #expect(Self.vocabulary.correcting(text, language: .english) == expected)
    }

    @Test(arguments: [
        ("I use Node.js here", "I use Node.js here"),
        ("I use node here", "I use Node.js here"),
        ("ask müller", "ask Dr. Müller"),
        ("ask dr. müller", "ask Dr. Müller"),
        ("ask Dr. Müller", "ask Dr. Müller"),
    ])
    func `keeps a term with punctuation whole`(text: String, expected: String) {
        let vocabulary = Vocabulary(
            terms: [Vocabulary.Term(term: "Node.js", spoken: ["node"]), Vocabulary.Term(term: "Dr. Müller", spoken: ["müller"])],
            snippets: [],
        )

        #expect(vocabulary.correcting(text, language: .english) == expected)
    }

    @Test(arguments: [("I use yahoo daily", "I use Yahoo! daily"), ("I use Yahoo! daily", "I use Yahoo! daily")])
    func `keeps a term that ends in punctuation whole`(text: String, expected: String) {
        let vocabulary = Vocabulary(terms: [Vocabulary.Term(term: "Yahoo!", spoken: ["yahoo"])], snippets: [])

        #expect(vocabulary.correcting(text, language: .english) == expected)
    }

    @Test
    func `matches a term with the letter case rules of the language`() {
        let vocabulary = Vocabulary(terms: [Vocabulary.Term(term: "İstanbul", spoken: [])], snippets: [])

        #expect(vocabulary.correcting("istanbul güzel", language: .turkish) == "İstanbul güzel")
    }

    @Test(arguments: ["cube, or netties", "kubernetesish", "cubes or netties", "c+"])
    func `leaves text that only resembles a term`(text: String) {
        #expect(Self.vocabulary.correcting(text, language: .english) == text)
    }

    @Test(arguments: [("카카오는 좋아요", "Kakao는 좋아요"), ("카카오가", "Kakao가"), ("카카오에서는", "카카오에서는")])
    func `keeps a short Korean particle after a term`(text: String, expected: String) {
        #expect(Self.vocabulary.correcting(text, language: .korean) == expected)
    }

    @Test(arguments: [("My email.", "me@example.com"), ("Sign off!", "Best regards,\nAnn")])
    func `expands a snippet only when it is the whole dictation`(text: String, expected: String) {
        #expect(Self.vocabulary.snippet(matchingWhole: text, language: .english) == expected)
    }

    @Test(arguments: ["send it to my email", "", "...", "email", "sign-off"])
    func `finds no snippet for other dictations`(text: String) {
        #expect(Self.vocabulary.snippet(matchingWhole: text, language: .english) == nil)
    }

    @Test
    func `expands snippets inside a sentence`() {
        let expanded = Self.vocabulary.expandingSnippets(in: "send it to my email, then sign off", language: .english)

        #expect(expanded == "send it to me@example.com, then Best regards,\nAnn")
    }

    @Test
    func `changes nothing without terms or snippets`() {
        #expect(Vocabulary.empty.correcting("cube or netties", language: .english) == "cube or netties")
        #expect(Vocabulary.empty.expandingSnippets(in: "my email", language: .english) == "my email")
    }

    @Test(arguments: [
        (#"{}"#, [Vocabulary.Term](), [String]()),
        (#"{"terms":[{"term":"Waft"}]}"#, [Vocabulary.Term(term: "Waft", spoken: [])], []),
        (#"{"terms":"bogus","snippets":[{"trigger":"brb","text":"Be right back"}]}"#, [], ["brb"]),
        (#"{"terms":[{"term":"Waft","spoken":"waft"}],"snippets":"bogus"}"#, [Vocabulary.Term(term: "Waft", spoken: [])], []),
        (
            #"{"terms":[{"term":"Waft","spoken":["waft",7]},{}],"snippets":[{"trigger":"brb","text":"Back"},{"trigger":"x"}]}"#,
            [Vocabulary.Term(term: "Waft", spoken: ["waft"])],
            ["brb"],
        ),
    ])
    func `decodes leniently`(json: String, terms: [Vocabulary.Term], triggers: [String]) throws {
        let vocabulary = try JSONDecoder().decode(Vocabulary.self, from: Data(json.utf8))

        #expect(vocabulary.terms == terms)
        #expect(vocabulary.snippets.map(\.trigger) == triggers)
    }

    @Test
    func `survives an encoding round trip`() throws {
        let data = try JSONEncoder().encode(Self.vocabulary)

        #expect(try JSONDecoder().decode(Vocabulary.self, from: data) == Self.vocabulary)
    }
}

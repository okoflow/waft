import Testing
@testable import WaftCore

struct StringCapitalizationTests {
    @Test(arguments: [
        ("hello world", "Hello world"),
        ("Hello world", "Hello world"),
        ("¿qué tal?", "¿Qué tal?"),
        ("42 apples", "42 Apples"),
        ("éclair", "Éclair"),
        ("привет", "Привет"),
        ("", ""),
        ("123", "123"),
    ])
    func `capitalizes the first letter`(text: String, expected: String) {
        #expect(text.capitalizingFirstLetter(in: .english) == expected)
    }

    @Test(arguments: [(Language.turkish, "İzmir"), (.azerbaijani, "İzmir"), (.english, "Izmir"), (.german, "Izmir")])
    func `capitalizes a dotted i only where the language has one`(language: Language, expected: String) {
        #expect("izmir".capitalizingFirstLetter(in: language) == expected)
    }

    @Test(arguments: [
        ("hello world", Language.english, "Hello world"),
        ("hello World", .english, "hello World"),
        ("hello, world", .english, "hello, world"),
        ("привет мир", .russian, "Привет мир"),
        ("こんにちは", .japanese, "こんにちは"),
        ("iyi günler", .turkish, "İyi günler"),
    ])
    func `capitalizes only unstyled text`(text: String, language: Language, expected: String) {
        #expect(text.capitalizedIfUnstyled(in: language) == expected)
    }
}

import Testing
@testable import WaftFeatures

struct StringCaptionTests {
    @Test(arguments: [
        ([], ""),
        (["12:30"], "\u{2068}12:30\u{2069}"),
        (["12:30", "Clean", "Notes"], "\u{2068}12:30\u{2069} · \u{2068}Clean\u{2069} · \u{2068}Notes\u{2069}"),
        (["English", "עברית"], "\u{2068}English\u{2069} · \u{2068}עברית\u{2069}"),
    ] as [([String], String)])
    func `joins the parts with a dot and isolates the direction of each`(parts: [String], expected: String) {
        #expect(String.caption(joining: parts) == expected)
    }
}

import Testing
import WaftCore

struct StringWritingVariantTests {
    @Test(arguments: [
        (WritingVariant?.none, "Srbija i Waft", "Srbija i Waft"),
        (.cyrillic, "Srbija i Waft", "Srbija и Waft"),
    ])
    func `writes the text in the variant and keeps the terms`(variant: WritingVariant?, text: String, expected: String) {
        #expect(text.written(in: variant, keeping: ["Srbija"]) == expected)
    }
}

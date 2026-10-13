import Testing
import WaftCore

struct WritingVariantTests {
    @Test(arguments: [
        (Language.chinese, [WritingVariant.simplified, .traditional]),
        (.serbian, [.latin, .cyrillic]),
        (.english, []),
    ])
    func `offers a choice of script only for Chinese and Serbian`(language: Language, variants: [WritingVariant]) {
        #expect(language.writingVariants == variants)
    }

    @Test(arguments: [
        (WritingVariant.traditional, "这是简体中文，我们说话。", "這是簡體中文，我們說話。"),
        (.simplified, "這是繁體中文，我們說話。", "这是繁体中文，我们说话。"),
        (.latin, "Србија, љубав, џеп, ЉУБАВ и ђак", "Srbija, ljubav, džep, LJUBAV i đak"),
        (.cyrillic, "Srbija, ljubav, džep, LJUBAV i đak", "Србија, љубав, џеп, ЉУБАВ и ђак"),
        (.cyrillic, "Njujork i nadživeti", "Њујорк и надживети"),
    ])
    func `converts the text into its script`(variant: WritingVariant, text: String, expected: String) {
        #expect(variant.converting(text) == expected)
    }

    @Test
    func `keeps foreign words, acronyms, and dictionary terms in Latin letters`() {
        let text = "Pusti GitHub, API i x264 na serveru Waft"

        #expect(WritingVariant.cyrillic.converting(text, keeping: ["Waft"]) == "Пусти GitHub, API и x264 на серверу Waft")
    }
}

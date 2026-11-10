import Testing
@testable import WaftCore

struct WritingVariantTests {
    @Test(arguments: [
        (WritingVariant.traditional, "这是简体中文，我们说话。", "這是簡體中文，我們說話。"),
        (.simplified, "這是繁體中文，我們說話。", "这是繁体中文，我们说话。"),
        (.latin, "Србија, љубав, џеп, ЉУБАВ и ђак", "Srbija, ljubav, džep, LJUBAV i đak"),
        (.cyrillic, "Srbija, ljubav, džep, LJUBAV i đak", "Србија, љубав, џеп, ЉУБАВ и ђак"),
        (.cyrillic, "Njujork i nadživeti", "Њујорк и надживети"),
        (.cyrillic, "Konjugovanje i nadživljavanje", "Конјуговање и надживљавање"),
    ])
    func `converts the text into its script`(variant: WritingVariant, text: String, expected: String) {
        #expect(variant.converting(text, keeping: []) == expected)
    }

    @Test
    func `keeps foreign words, acronyms, and dictionary terms in Latin letters`() {
        let text = "Pusti GitHub, API i x264 na serveru Waft"

        #expect(WritingVariant.cyrillic.converting(text, keeping: ["Waft"]) == "Пусти GitHub, API и x264 на серверу Waft")
    }

    @Test(arguments: [
        (WritingVariant.latin, "Отвори Яндекс и Waft", ["Яндекс"], "Otvori Яндекс i Waft"),
        (.simplified, "我去臺灣開會", ["臺灣"], "我去臺灣开会"),
        (.traditional, "我用头条看新闻", ["头条"], "我用头条看新聞"),
        (.simplified, "臺灣的臺北", ["臺灣", "臺北"], "臺灣的臺北"),
    ])
    func `keeps a dictionary term as written in every variant`(
        variant: WritingVariant,
        text: String,
        terms: [String],
        expected: String,
    ) {
        #expect(variant.converting(text, keeping: terms) == expected)
    }

    @Test(arguments: [
        ("Novi Sad je lep grad", "Novi Sad је леп град"),
        ("Sad idem u Novi Sad", "Сад идем у Novi Sad"),
        ("Coca-Cola je slatka", "Coca-Cola је слатка"),
    ])
    func `keeps a whole dictionary term in Latin letters`(text: String, expected: String) {
        #expect(WritingVariant.cyrillic.converting(text, keeping: ["Novi Sad", "Coca-Cola"]) == expected)
    }
}

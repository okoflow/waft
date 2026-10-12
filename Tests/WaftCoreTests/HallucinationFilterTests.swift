import Testing
import WaftCore

struct HallucinationFilterTests {
    @Test(arguments: [
        "[Music]",
        "(applause)",
        "♪ ♪ ♪",
        "*laughs*",
        "[музыка]",
        "【音楽】",
        "（笑）",
        "[BLANK_AUDIO] [Music]",
        "...",
        "",
    ])
    func `drops text made only of sound tags`(text: String) {
        #expect(HallucinationFilter.isHallucination(text, in: .english, prompt: nil))
    }

    @Test(arguments: ["[Music] hello", "Hello (quietly)", "♪ la la ♪", "3 [beep]"])
    func `keeps speech next to sound tags`(text: String) {
        #expect(!HallucinationFilter.isHallucination(text, in: .english, prompt: nil))
    }

    @Test(arguments: [
        ("Thanks for watching!", Language.english),
        ("Thank you for watching.", .english),
        ("PLEASE SUBSCRIBE", .english),
        ("Продолжение следует...", .russian),
        ("Субтитры сделал DimaTorzok", .russian),
        ("Спасибо за просмотр!", .russian),
        ("ご視聴ありがとうございました", .japanese),
        ("Untertitel im Auftrag des ZDF, 2021", .german),
    ])
    func `drops stock subtitle phrases`(text: String, language: Language) {
        #expect(HallucinationFilter.isHallucination(text, in: language, prompt: nil))
    }

    @Test(arguments: [
        ("Thanks for watching the game with me", Language.english),
        ("Thanks for watching", .russian),
        ("Субтитры сделал мой друг вчера вечером", .russian),
    ])
    func `keeps stock phrases with real speech after them or in another language`(text: String, language: Language) {
        #expect(!HallucinationFilter.isHallucination(text, in: language, prompt: nil))
    }

    @Test
    func `drops an echo of the prompt`() {
        let prompt = "Hello! This is a sample of text, with capital letters, commas and full stops. Waft, Kubernetes."
        let echo = "This is a sample of text with capital letters, commas and full stops."

        #expect(HallucinationFilter.isHallucination(echo, in: .english, prompt: prompt))
        #expect(!HallucinationFilter.isHallucination(echo, in: .english, prompt: nil))
    }

    @Test
    func `keeps a short phrase that happens to appear in the prompt`() {
        let prompt = "Hello! This is a sample of text, with capital letters, commas and full stops."

        #expect(!HallucinationFilter.isHallucination("Hello!", in: .english, prompt: prompt))
    }

    @Test(arguments: [(-1.0, 2.0, true), (-1.5, 2.4, true), (-1.6, 2.0, false), (-1.0, 2.5, false)])
    func `keeps segments that are confident and not repetitive`(logProbability: Double, compression: Double, keeps: Bool) {
        #expect(HallucinationFilter.keepsSegment(averageLogProbability: logProbability, compressionRatio: compression) == keeps)
    }
}

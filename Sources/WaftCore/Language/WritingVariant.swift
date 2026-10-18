import Foundation

package enum WritingVariant: String, CaseIterable, Codable, Sendable {
    case simplified
    case traditional
    case latin
    case cyrillic

    package var nativeName: String {
        switch self {
        case .simplified: "简体"
        case .traditional: "繁體"
        case .latin: "Latinica"
        case .cyrillic: "Ћирилица"
        }
    }

    var styleSentence: String {
        switch self {
        case .simplified: "你好！这是一段示例文本，包含逗号和句号。"
        case .traditional: "你好！這是一段示例文本，包含逗號和句號。"
        case .latin: "Zdravo! Ovo je primer teksta sa velikim slovima, zarezima i tačkama."
        case .cyrillic: "Здраво! Ово је пример текста са великим словима, зарезима и тачкама."
        }
    }

    private static func transformed(_ text: String, by transform: String) -> String {
        guard let result = text.applyingTransform(StringTransform(transform), reverse: false) else { return text }

        return result
    }

    func converting(_ text: String, keeping terms: [String] = []) -> String {
        switch self {
        case .simplified: Self.transformed(text, by: "Hant-Hans")
        case .traditional: Self.transformed(text, by: "Hans-Hant")
        case .latin: Self.transformed(text, by: "Serbian-Latin/BGN")
        case .cyrillic: SerbianCyrillic.converting(text, keeping: terms)
        }
    }
}

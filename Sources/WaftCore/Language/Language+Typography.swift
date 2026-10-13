extension Language {
    var scripts: Set<WritingScript> {
        switch self {
        case .arabic, .urdu:
            [.arabic]
        case .bulgarian, .macedonian, .russian, .ukrainian:
            [.cyrillic]
        case .chinese:
            [.han]
        case .greek:
            [.greek]
        case .hebrew:
            [.hebrew]
        case .hindi:
            [.devanagari]
        case .japanese:
            [.han, .kana]
        case .korean:
            [.hangul]
        case .serbian:
            [.cyrillic, .latin]
        case .tamil:
            [.tamil]
        case .thai:
            [.thai]
        case .azerbaijani, .bosnian, .catalan, .croatian, .czech, .danish, .dutch, .english, .estonian, .filipino, .finnish,
             .french, .galician, .german, .hungarian, .indonesian, .italian, .latvian, .lithuanian, .malay, .norwegian,
             .polish, .portuguese, .romanian, .slovak, .slovenian, .spanish, .swedish, .turkish, .vietnamese:
            [.latin]
        }
    }

    var hasLetterCase: Bool {
        scripts.contains(where: \.hasLetterCase)
    }

    var separatesWordsWithSpaces: Bool {
        scripts.allSatisfy(\.separatesWordsWithSpaces)
    }

    var hasLooseWordSpacing: Bool {
        scripts.contains(where: \.hasLooseWordSpacing)
    }

    var spacesBeforeHighPunctuation: Bool {
        self == .french
    }

    var fullStop: String {
        switch self {
        case .chinese, .japanese:
            "。"
        case .hindi:
            "।"
        case .thai:
            ""
        case .urdu:
            "۔"
        default:
            "."
        }
    }

    var questionMark: Character {
        switch self {
        case .arabic, .urdu:
            "؟"
        case .chinese, .japanese:
            "？"
        case .greek:
            ";"
        default:
            "?"
        }
    }

    var hasDottedCapitalI: Bool {
        self == .azerbaijani || self == .turkish
    }
}

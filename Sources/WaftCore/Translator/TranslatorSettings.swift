package struct TranslatorSettings: Codable, Equatable, Sendable {
    private static let maximumRecentCount = 3

    package var source: Language?
    package var translation: Translation
    package var instructions = EditableInstructions<TextTask.Kind>()
    package var cloudModel = CloudModel.balanced
    package private(set) var recentLanguages: [Language] = []

    package init(translation: Translation = Translation()) {
        self.translation = translation
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        source = container.decodeIfValid(.source)
        translation = container.decode(.translation, default: Translation())
        instructions = container.decode(.instructions, default: instructions)
        cloudModel = container.decode(.cloudModel, default: cloudModel)
        recentLanguages = Array(container.decodeValidElements(.recentLanguages).prefix(Self.maximumRecentCount))
    }

    package func trustedSource(detected: Language?) -> Language? {
        guard let source else { return nil }

        let pair: [Language?] = [translation.target, translation.twoWayLanguage]
        guard let detected, detected != source, pair.contains(detected) else { return source }

        return nil
    }

    package func knownSource(detected: Language?) -> Language? {
        guard let trusted = trustedSource(detected: detected) else { return detected }

        return trusted
    }

    package func swapped(from: Language) -> Translation {
        let into = target(forSource: from)

        guard let twoWayLanguage = translation.twoWayLanguage,
              ![translation.target, twoWayLanguage].contains(from) else {
            return Translation(target: from, twoWayLanguage: into)
        }

        return Translation(target: from, twoWayLanguage: twoWayLanguage)
    }

    package func target(forSource spoken: Language?) -> Language {
        guard let spoken else { return translation.target }
        guard spoken == translation.target, translation.twoWayLanguage == nil, let source, source != spoken else {
            return translation.target(forSpoken: spoken)
        }

        return source
    }

    package mutating func remember(_ language: Language) {
        recentLanguages.removeAll { $0 == language }
        recentLanguages.insert(language, at: 0)
        recentLanguages = Array(recentLanguages.prefix(Self.maximumRecentCount))
    }
}

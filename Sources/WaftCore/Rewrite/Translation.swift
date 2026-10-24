package struct Translation: Codable, Equatable, Sendable {
    package var target: Language {
        didSet { dropTwoWayLanguageEqualToTarget() }
    }

    package var twoWayLanguage: Language? {
        didSet { dropTwoWayLanguageEqualToTarget() }
    }

    package init(target: Language = .english, twoWayLanguage: Language? = nil) {
        self.target = target
        self.twoWayLanguage = twoWayLanguage == target ? nil : twoWayLanguage
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(target: container.decode(.target, default: .english), twoWayLanguage: container.decodeIfValid(.twoWayLanguage))
    }

    func target(forSpoken spoken: Language) -> Language {
        guard spoken == target, let twoWayLanguage else { return target }

        return twoWayLanguage
    }

    private mutating func dropTwoWayLanguageEqualToTarget() {
        guard twoWayLanguage == target else { return }

        twoWayLanguage = nil
    }
}

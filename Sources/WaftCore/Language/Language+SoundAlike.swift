extension Language {
    private static let soundAlikeGroups: [[Language]] = [
        [.russian, .ukrainian],
        [.danish, .norwegian],
        [.indonesian, .malay],
        [.serbian, .croatian, .bosnian],
        [.czech, .slovak],
        [.bulgarian, .macedonian],
        [.hindi, .urdu],
    ]

    package static func soundAlike(among languages: [Language]) -> [Language] {
        let groups = soundAlikeGroups.map { group in group.filter(languages.contains) }
        guard let alike = groups.first(where: { $0.count > 1 }) else { return [] }

        return alike
    }
}

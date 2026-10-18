extension Character {
    private static let pauseMarks: Set<Character> = [
        ".",
        ",",
        "!",
        "?",
        ";",
        ":",
        "…",
        "。",
        "，",
        "、",
        "！",
        "？",
        "：",
        "；",
        "،",
        "؛",
        "؟",
        "۔",
        "।",
        "॥",
    ]

    var isPauseMark: Bool {
        Self.pauseMarks.contains(self)
    }
}

package enum ShortcutAction: String, CaseIterable, CodingKey, Sendable {
    case modeCycle
    case translator
    case translateSelection
    case fixSelection

    private static let letterT: Int64 = 17
    private static let letterM: Int64 = 46
    private static let letterF: Int64 = 3

    package var defaultCombination: KeyCombination {
        switch self {
        case .modeCycle: KeyCombination(keyCode: Self.letterM, modifiers: [.control, .option])
        case .translator: KeyCombination(keyCode: Self.letterT, modifiers: [.control, .option])
        case .translateSelection: KeyCombination(keyCode: Self.letterT, modifiers: [.control, .option, .shift])
        case .fixSelection: KeyCombination(keyCode: Self.letterF, modifiers: [.control, .option])
        }
    }
}

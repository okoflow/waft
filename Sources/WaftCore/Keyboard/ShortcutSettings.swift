package struct ShortcutSettings: Codable, Equatable, Sendable {
    private var combinations: [ShortcutAction: KeyCombination]

    package init() {
        combinations = Dictionary(uniqueKeysWithValues: ShortcutAction.allCases.map { ($0, $0.defaultCombination) })
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: ShortcutAction.self)

        combinations = [:]

        for action in ShortcutAction.allCases {
            combinations[action] = Self.decode(action, in: container)
        }
    }

    private static func decode(
        _ action: ShortcutAction,
        in container: KeyedDecodingContainer<ShortcutAction>,
    ) -> KeyCombination? {
        let isCleared = try? container.decodeNil(forKey: action)
        guard isCleared != true else { return nil }

        return container.decode(action, default: action.defaultCombination)
    }

    package subscript(_ action: ShortcutAction) -> KeyCombination? {
        get { combinations[action] }
        set { combinations[action] = newValue }
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ShortcutAction.self)

        for action in ShortcutAction.allCases {
            try container.encode(combinations[action], forKey: action)
        }
    }

    package func action(using combination: KeyCombination) -> ShortcutAction? {
        ShortcutAction.allCases.first { combinations[$0] == combination }
    }

    package func canReset(_ action: ShortcutAction) -> Bool {
        let fallback = action.defaultCombination

        guard combinations[action] != fallback else { return false }

        return self.action(using: fallback) == nil
    }

    package mutating func reset(_ action: ShortcutAction) {
        guard canReset(action) else { return }

        combinations[action] = action.defaultCombination
    }
}

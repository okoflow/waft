package struct AppModeOverrides: Codable, Equatable, Sendable {
    private var modes: [String: Mode] = [:]

    package var bundleIdentifiers: [String] {
        modes.keys.sorted()
    }

    package func mode(for bundleIdentifier: String?) -> Mode? {
        bundleIdentifier.flatMap { modes[$0] }
    }

    package mutating func set(_ mode: Mode?, for bundleIdentifier: String) {
        modes[bundleIdentifier] = mode
    }

    package mutating func add(_ mode: Mode, for bundleIdentifier: String) {
        guard modes[bundleIdentifier] == nil else { return }

        modes[bundleIdentifier] = mode
    }

    mutating func removeModes(where shouldRemove: (Mode) -> Bool) {
        modes = modes.filter { !shouldRemove($0.value) }
    }
}

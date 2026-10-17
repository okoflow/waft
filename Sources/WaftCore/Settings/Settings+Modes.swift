extension Settings {
    package var modes: [Mode] {
        Mode.builtIn + customModeChoices
    }

    package var customModeChoices: [Mode] {
        customModes.map { .custom($0.id) }
    }

    private static func isAvailable(_ mode: Mode, among ids: Set<CustomMode.ID>) -> Bool {
        guard case let .custom(id) = mode else { return true }

        return ids.contains(id)
    }

    package func customMode(_ id: CustomMode.ID) -> CustomMode? {
        customModes.first { $0.id == id }
    }

    package func title(of mode: Mode) -> String {
        guard case let .custom(id) = mode, let custom = customMode(id), !custom.name.isBlank else { return mode.title }

        return custom.name
    }

    package func summary(of mode: Mode) -> String {
        guard case let .custom(id) = mode, let custom = customMode(id), !custom.instructions.isBlank else {
            return mode.summary
        }

        return custom.instructions
    }

    package func rewriteSetup(for mode: Mode) -> RewriteSetup {
        RewriteSetup(
            provider: modelProvider,
            instructions: rewriteInstructions(for: mode),
            cloudModels: cloudModels,
            translation: translation,
            localServer: localServer,
        )
    }

    package func mode(after current: Mode, includingAI: Bool) -> Mode {
        let available = modes.filter { includingAI || !$0.usesAI }
        guard let index = available.firstIndex(of: current) else { return .light }

        return available[(index + 1) % available.count]
    }

    package mutating func addCustomMode(named name: String) -> CustomMode {
        let custom = CustomMode(name: name, instructions: "")
        customModes.append(custom)

        return custom
    }

    package mutating func update(_ custom: CustomMode) {
        guard let index = customModes.firstIndex(where: { $0.id == custom.id }) else { return }

        customModes[index] = custom
    }

    package mutating func removeCustomMode(_ id: CustomMode.ID) {
        customModes.removeAll { $0.id == id }
        dropMissingCustomModes()
    }

    mutating func dropMissingCustomModes() {
        let ids = Set(customModes.map(\.id))

        if !Self.isAvailable(mode, among: ids) {
            mode = .light
        }

        appModes.removeModes { !Self.isAvailable($0, among: ids) }
    }

    private func rewriteInstructions(for mode: Mode) -> String {
        guard case let .custom(id) = mode else { return instructions.text(for: mode) }
        guard let custom = customMode(id), !custom.instructions.isBlank else { return instructions.text(for: .clean) }

        return RewritePrompt.customInstructions(custom.instructions)
    }
}

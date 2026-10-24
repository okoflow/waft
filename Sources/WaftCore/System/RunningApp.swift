package struct RunningApp: Equatable, Sendable {
    package let bundleIdentifier: String
    package let name: String

    package static func trackable(bundleIdentifier: String?, name: String?) -> RunningApp? {
        guard let bundleIdentifier, bundleIdentifier != AppIdentity.bundleIdentifier else { return nil }
        guard let name else { return RunningApp(bundleIdentifier: bundleIdentifier, name: bundleIdentifier) }

        return RunningApp(bundleIdentifier: bundleIdentifier, name: name)
    }
}

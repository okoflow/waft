package struct RunningApp: Equatable, Sendable {
    package let bundleIdentifier: String
    package let name: String

    package init(bundleIdentifier: String, name: String) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
    }
}

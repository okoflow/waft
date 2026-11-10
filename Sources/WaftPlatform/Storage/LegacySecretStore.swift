protocol LegacySecretStore: Sendable {
    func load() throws -> String?
    func delete() throws
    func exists() -> Bool
}

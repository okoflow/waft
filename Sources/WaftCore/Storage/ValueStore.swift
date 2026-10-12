package protocol ValueStore<Value>: Sendable {
    associatedtype Value: Sendable

    var name: String { get }

    func load() throws -> Value?
    func save(_ value: Value) throws
    func delete() throws
    func exists() -> Bool
}

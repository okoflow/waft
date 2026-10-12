package struct License: Decodable, Equatable, Sendable {
    package let email: String
    package let name: String?

    package var holder: String {
        guard let name, !name.isEmpty else { return email }

        return name
    }
}

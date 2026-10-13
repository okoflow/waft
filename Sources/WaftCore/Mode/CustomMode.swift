package import Foundation

package struct CustomMode: Codable, Equatable, Identifiable, Sendable {
    package let id: UUID
    package var name: String
    package var instructions: String

    package init(name: String, instructions: String, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.instructions = instructions
    }
}

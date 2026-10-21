import Foundation
import Testing
import WaftCore

struct ModeTests {
    private static let customID = UUID()

    @Test(arguments: [
        ("raw", Mode.raw),
        ("light", .light),
        ("clean", .clean),
        ("formal", .formal),
        ("translate", .translate),
        ("custom:\(customID.uuidString)", .custom(customID)),
    ])
    func `encodes to its stored key`(storageKey: String, mode: Mode) throws {
        let data = try JSONEncoder().encode(mode)

        #expect(data == Data("\"\(storageKey)\"".utf8))
        #expect(try JSONDecoder().decode(Mode.self, from: data) == mode)
        #expect(Mode(rawValue: storageKey) == mode)
    }

    @Test(arguments: ["", "bogus", "Clean", "custom:", "custom:not-a-uuid"])
    func `rejects an unknown storage key`(storageKey: String) {
        #expect(Mode(rawValue: storageKey) == nil)
    }
}

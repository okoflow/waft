import CoreGraphics
import Testing
@testable import WaftPlatform

struct CGEventOwnProcessTests {
    @Test
    func `tells a key event of its own process from another process's`() throws {
        let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true))

        #expect(event.isFromOwnProcess)

        event.setIntegerValueField(.eventSourceUnixProcessID, value: 1)

        #expect(!event.isFromOwnProcess)
    }
}

import CoreGraphics
import Testing
import WaftCore
@testable import WaftPlatform

struct KeyEventKindCGEventTypeTests {
    @Test(arguments: [
        (CGEventType.flagsChanged, KeyEvent.Kind.modifiersChanged),
        (.keyDown, .keyDown),
        (.keyUp, .keyUp),
        (.tapDisabledByTimeout, .monitorDisabled),
        (.tapDisabledByUserInput, .monitorDisabled),
        (.mouseMoved, nil),
    ] as [(CGEventType, KeyEvent.Kind?)])
    func `maps an event tap type to a key event kind`(type: CGEventType, kind: KeyEvent.Kind?) {
        #expect(KeyEvent.Kind(type) == kind)
    }
}

import AppKit
import Testing

extension NSEvent {
    static func key(keyCode: UInt16, type: NSEvent.EventType = .keyDown, flags: NSEvent.ModifierFlags = []) throws -> NSEvent {
        try #require(keyEvent(
            with: type,
            location: .zero,
            modifierFlags: flags,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: keyCode,
        ))
    }
}

import Carbon.HIToolbox
import CoreGraphics
import os

@MainActor
enum PasteShortcut {
    private static let fallbackKeyCode = CGKeyCode(kVK_ANSI_V)
    private static let commandModifierState = UInt32((cmdKey >> 8) & 0xFF)
    private static let leftCommandDeviceFlag: UInt64 = 0x08

    static func post() {
        let source = CGEventSource(stateID: .hidSystemState)
        let leftCommand = CGKeyCode(kVK_Command)
        let vKey = keyCodeTypingV()
        let commandFlags = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | leftCommandDeviceFlag)

        post(leftCommand, isDown: true, flags: commandFlags, isModifier: true, source: source)
        post(vKey, isDown: true, flags: commandFlags, isModifier: false, source: source)
        post(vKey, isDown: false, flags: commandFlags, isModifier: false, source: source)
        post(leftCommand, isDown: false, flags: [], isModifier: true, source: source)
    }

    private static func post(_ keyCode: CGKeyCode, isDown: Bool, flags: CGEventFlags, isModifier: Bool, source: CGEventSource?) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: isDown) else {
            Logger.insertion.error("Couldn't create the event for key code \(keyCode, privacy: .public)")

            return
        }

        if isModifier {
            event.type = .flagsChanged
        }

        event.flags = flags
        event.post(tap: .cghidEventTap)
    }

    private static func keyCodeTypingV() -> CGKeyCode {
        guard let eventSource = CGEventSource(stateID: .combinedSessionState) else { return fallbackKeyCode }

        let keyboardType = UInt32(eventSource.keyboardType)
        let keyCode = CurrentKeyboardLayout.withCurrentLayout { layout in
            (UInt16(0) ..< 128).first { keyCode in
                let character = CurrentKeyboardLayout.translate(
                    keyCode,
                    with: layout,
                    modifierState: commandModifierState,
                    keyboardType: keyboardType,
                )

                return character == "v"
            }
        }

        guard let keyCode else { return fallbackKeyCode }

        return keyCode
    }
}

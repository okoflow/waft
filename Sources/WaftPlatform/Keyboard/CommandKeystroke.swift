import Carbon.HIToolbox
import CoreGraphics
import os

@MainActor
enum CommandKeystroke {
    case copy
    case paste

    private static let commandModifierState = UInt32((cmdKey >> 8) & 0xFF)
    private static let leftCommandDeviceFlag: UInt64 = 0x08

    private var character: String {
        switch self {
        case .copy: "c"
        case .paste: "v"
        }
    }

    private var fallbackKeyCode: CGKeyCode {
        switch self {
        case .copy: CGKeyCode(kVK_ANSI_C)
        case .paste: CGKeyCode(kVK_ANSI_V)
        }
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

    func post() {
        let source = CGEventSource(stateID: .hidSystemState)
        let leftCommand = CGKeyCode(kVK_Command)
        let key = keyCode()
        let commandFlags = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | Self.leftCommandDeviceFlag)

        Self.post(leftCommand, isDown: true, flags: commandFlags, isModifier: true, source: source)
        Self.post(key, isDown: true, flags: commandFlags, isModifier: false, source: source)
        Self.post(key, isDown: false, flags: commandFlags, isModifier: false, source: source)
        Self.post(leftCommand, isDown: false, flags: [], isModifier: true, source: source)
    }

    private func keyCode() -> CGKeyCode {
        guard let eventSource = CGEventSource(stateID: .combinedSessionState) else { return fallbackKeyCode }

        let keyboardType = UInt32(eventSource.keyboardType)
        let keyCode = CurrentKeyboardLayout.withCurrentLayout { layout in
            (UInt16(0) ..< 128).first { keyCode in
                let typed = CurrentKeyboardLayout.translate(
                    keyCode,
                    with: layout,
                    modifierState: Self.commandModifierState,
                    keyboardType: keyboardType,
                )

                return typed == character
            }
        }

        guard let keyCode else { return fallbackKeyCode }

        return keyCode
    }
}

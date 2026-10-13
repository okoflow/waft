import Carbon.HIToolbox
import os
import WaftCore

@MainActor
package final class CarbonHotKey: GlobalShortcut {
    private static let signature = OSType(0x5761_6674)
    private static let identifier: UInt32 = 1
    private static let keyCode = UInt32(kVK_ANSI_M)
    private static let modifiers = UInt32(controlKey | optionKey)

    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var action: (@MainActor () -> Void)?

    package var title: String {
        "⌃⌥M"
    }

    private init() {}

    package static func modeCycle() -> CarbonHotKey {
        CarbonHotKey()
    }

    package func register(_ action: @escaping @MainActor () -> Void) -> Bool {
        guard hotKey == nil else { return true }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotKeyCallback,
            1,
            &eventType,
            context,
            &handler,
        )

        guard installStatus == noErr else {
            Logger.keyboard.error("Couldn't install the mode shortcut handler: OSStatus \(installStatus, privacy: .public)")

            return false
        }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.identifier)
        let registerStatus = RegisterEventHotKey(Self.keyCode, Self.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKey)
        guard registerStatus == noErr else {
            Logger.keyboard.error("Couldn't register the mode shortcut: OSStatus \(registerStatus, privacy: .public)")

            RemoveEventHandler(handler)
            handler = nil

            return false
        }

        self.action = action

        return true
    }

    fileprivate func handle(_ pressed: EventHotKeyID) -> OSStatus {
        guard pressed.signature == Self.signature, pressed.id == Self.identifier else { return OSStatus(eventNotHandledErr) }

        action?()

        return noErr
    }
}

private let carbonHotKeyCallback: EventHandlerUPP = { _, event, context in
    guard let context, let pressed = pressedHotKey(in: event) else { return OSStatus(eventNotHandledErr) }

    let hotKey = Unmanaged<CarbonHotKey>.fromOpaque(context).takeUnretainedValue()

    return MainActor.assumeIsolated { hotKey.handle(pressed) }
}

private func pressedHotKey(in event: EventRef?) -> EventHotKeyID? {
    var pressed = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &pressed,
    )

    return status == noErr ? pressed : nil
}

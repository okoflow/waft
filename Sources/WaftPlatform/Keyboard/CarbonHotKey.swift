import Carbon.HIToolbox
import os
import WaftCore

@MainActor
package final class CarbonHotKey: GlobalShortcut {
    private static let signature = OSType(0x5761_6674)
    private static let controlOption = controlKey | optionKey

    package let title: String

    private let identifier: UInt32
    private let keyCode: UInt32
    private let modifiers: UInt32

    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var action: (@MainActor () -> Void)?

    private init(identifier: UInt32, keyCode: Int, modifiers: Int, title: String) {
        self.identifier = identifier
        self.keyCode = UInt32(keyCode)
        self.modifiers = UInt32(modifiers)
        self.title = title
    }

    package static func modeCycle() -> CarbonHotKey {
        CarbonHotKey(identifier: 1, keyCode: kVK_ANSI_M, modifiers: controlOption, title: "⌃⌥M")
    }

    package static func translator() -> CarbonHotKey {
        CarbonHotKey(identifier: 2, keyCode: kVK_ANSI_T, modifiers: controlOption, title: "⌃⌥T")
    }

    package static func translateSelection() -> CarbonHotKey {
        CarbonHotKey(identifier: 3, keyCode: kVK_ANSI_T, modifiers: controlOption | shiftKey, title: "⌃⌥⇧T")
    }

    package static func fixSelection() -> CarbonHotKey {
        CarbonHotKey(identifier: 4, keyCode: kVK_ANSI_F, modifiers: controlOption, title: "⌃⌥F")
    }

    package func register(_ action: @escaping @MainActor () -> Void) -> Bool {
        guard hotKey == nil else { return true }

        let shortcut = title
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
            Logger.keyboard.error(
                "Couldn't install the \(shortcut, privacy: .public) handler: OSStatus \(installStatus, privacy: .public)",
            )

            return false
        }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: identifier)
        let registerStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKey)
        guard registerStatus == noErr else {
            Logger.keyboard.error(
                "Couldn't register the \(shortcut, privacy: .public) shortcut: OSStatus \(registerStatus, privacy: .public)",
            )

            RemoveEventHandler(handler)
            handler = nil

            return false
        }

        self.action = action

        return true
    }

    fileprivate func handle(_ pressed: EventHotKeyID) -> OSStatus {
        guard pressed.signature == Self.signature, pressed.id == identifier else { return OSStatus(eventNotHandledErr) }

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

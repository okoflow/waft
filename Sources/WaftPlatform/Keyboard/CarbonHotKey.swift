package import WaftCore
import Carbon.HIToolbox
import os

@MainActor
package final class CarbonHotKey: GlobalShortcut {
    private static let signature = OSType(0x5761_6674)
    private static var lastIdentifier: UInt32 = 0

    private let identifier: UInt32

    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var action: (@MainActor () -> Void)?

    package init() {
        Self.lastIdentifier += 1
        identifier = Self.lastIdentifier
    }

    private static func carbonModifiers(of modifiers: KeyCombination.Modifiers) -> UInt32 {
        let flags: [(KeyCombination.Modifiers, Int)] = [
            (.control, controlKey),
            (.option, optionKey),
            (.shift, shiftKey),
            (.command, cmdKey),
        ]

        return flags.filter { modifiers.contains($0.0) }.reduce(0) { $0 | UInt32($1.1) }
    }

    package func register(_ combination: KeyCombination, action: @escaping @MainActor () -> Void) -> Bool {
        unregister()

        let shortcut = identifier
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
                "Couldn't install shortcut \(shortcut, privacy: .public): OSStatus \(installStatus, privacy: .public)",
            )

            return false
        }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: identifier)
        let registerStatus = RegisterEventHotKey(
            UInt32(combination.keyCode),
            Self.carbonModifiers(of: combination.modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey,
        )

        guard registerStatus == noErr else {
            Logger.keyboard.error(
                "Couldn't register shortcut \(shortcut, privacy: .public): OSStatus \(registerStatus, privacy: .public)",
            )

            unregister()

            return false
        }

        self.action = action

        return true
    }

    package func unregister() {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
        }

        if let handler {
            RemoveEventHandler(handler)
        }

        hotKey = nil
        handler = nil
        action = nil
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

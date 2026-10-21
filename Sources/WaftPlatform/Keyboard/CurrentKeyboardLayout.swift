import Carbon.HIToolbox
import Foundation
import WaftCore

@MainActor
package final class CurrentKeyboardLayout: KeyboardLayout {
    private static let maximumLength = 4

    package init() {}

    static func withCurrentLayout<Result>(_ body: (UnsafePointer<UCKeyboardLayout>) -> Result?) -> Result? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let property = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }

        let layoutData = Unmanaged<CFData>.fromOpaque(property).takeUnretainedValue() as Data

        return layoutData.withUnsafeBytes { bytes in
            guard let layout = bytes.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return nil }

            return body(layout)
        }
    }

    static func translate(
        _ keyCode: UInt16,
        with layout: UnsafePointer<UCKeyboardLayout>,
        modifierState: UInt32 = 0,
        keyboardType: UInt32 = UInt32(LMGetKbdType()),
    ) -> String? {
        var deadKeyState: UInt32 = 0
        var characters = [UniChar](repeating: 0, count: maximumLength)
        var length = 0
        let status = UCKeyTranslate(
            layout,
            keyCode,
            UInt16(kUCKeyActionDisplay),
            modifierState,
            keyboardType,
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            maximumLength,
            &length,
            &characters,
        )

        guard status == noErr, length > 0 else { return nil }

        return String(utf16CodeUnits: characters, count: length)
    }

    package func character(forKeyCode keyCode: Int64) -> String? {
        Self.withCurrentLayout { Self.translate(UInt16(keyCode), with: $0) }
    }
}

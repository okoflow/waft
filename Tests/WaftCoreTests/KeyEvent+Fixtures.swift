import Foundation
import WaftCore

extension KeyEvent {
    static let rightOptionFlag: UInt64 = 0x40
    static let f5KeyCode: Int64 = 96
    static let escapeKeyCode: Int64 = 53
    static let monitorDisabled = KeyEvent(kind: .monitorDisabled, keyCode: 0, flags: 0, isRepeat: false, timestamp: 0)

    static func modifiersChanged(_ keyCode: Int64, flags: UInt64 = 0) -> KeyEvent {
        KeyEvent(kind: .modifiersChanged, keyCode: keyCode, flags: flags, isRepeat: false, timestamp: 0)
    }

    static func keyDown(_ keyCode: Int64, flags: UInt64 = 0, isRepeat: Bool = false, at timestamp: TimeInterval = 0) -> KeyEvent {
        KeyEvent(kind: .keyDown, keyCode: keyCode, flags: flags, isRepeat: isRepeat, timestamp: timestamp)
    }

    static func keyUp(_ keyCode: Int64) -> KeyEvent {
        KeyEvent(kind: .keyUp, keyCode: keyCode, flags: 0, isRepeat: false, timestamp: 0)
    }
}

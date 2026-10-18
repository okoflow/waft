package import Foundation

package struct KeyEvent: Sendable {
    package enum Kind: Sendable {
        case modifiersChanged
        case keyDown
        case keyUp
        case monitorDisabled
    }

    private static let escapeKeyCode: Int64 = 53

    package let kind: Kind
    package let keyCode: Int64
    package let timestamp: TimeInterval

    let flags: UInt64
    let isRepeat: Bool

    var isEscape: Bool {
        keyCode == Self.escapeKeyCode
    }

    package init(kind: Kind, keyCode: Int64, flags: UInt64, isRepeat: Bool, timestamp: TimeInterval) {
        self.kind = kind
        self.keyCode = keyCode
        self.flags = flags
        self.isRepeat = isRepeat
        self.timestamp = timestamp
    }
}

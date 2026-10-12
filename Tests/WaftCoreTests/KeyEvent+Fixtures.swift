import WaftCore

extension KeyEvent {
    static let rightOptionFlag: UInt64 = 0x40
    static let f5KeyCode: Int64 = 96

    init(_ kind: Kind, keyCode: Int64, flags: UInt64 = 0, isRepeat: Bool = false) {
        self.init(kind: kind, keyCode: keyCode, flags: flags, isRepeat: isRepeat, timestamp: 0)
    }
}

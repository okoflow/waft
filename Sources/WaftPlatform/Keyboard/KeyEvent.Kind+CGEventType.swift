import CoreGraphics
import WaftCore

extension KeyEvent.Kind {
    init?(_ type: CGEventType) {
        switch type {
        case .keyDown: self = .keyDown
        case .keyUp: self = .keyUp
        case .flagsChanged: self = .modifiersChanged
        case .tapDisabledByTimeout, .tapDisabledByUserInput: self = .monitorDisabled
        default: return nil
        }
    }
}

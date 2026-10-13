import CoreGraphics
import WaftCore

extension KeyEvent.Kind {
    init?(_ type: CGEventType) {
        switch type {
        case .flagsChanged: self = .modifiersChanged
        case .keyDown: self = .keyDown
        case .keyUp: self = .keyUp
        case .tapDisabledByTimeout, .tapDisabledByUserInput: self = .monitorDisabled
        default: return nil
        }
    }
}

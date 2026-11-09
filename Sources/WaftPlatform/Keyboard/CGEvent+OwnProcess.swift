import CoreGraphics
import Foundation

extension CGEvent {
    var isFromOwnProcess: Bool {
        getIntegerValueField(.eventSourceUnixProcessID) == Int64(getpid())
    }
}

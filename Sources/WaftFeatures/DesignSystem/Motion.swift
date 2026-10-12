import SwiftUI

enum Motion {
    static let feedback = Animation.snappy(duration: 0.2)
    static let layout = Animation.smooth(duration: 0.3)
    static let page = Animation.smooth(duration: 0.4)
    static let fade = Animation.easeOut(duration: 0.15)
    static let meter = Animation.smooth(duration: 0.12)
    static let reduced = Animation.easeInOut(duration: 0.15)
}

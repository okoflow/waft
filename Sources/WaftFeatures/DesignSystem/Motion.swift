import SwiftUI

enum Motion {
    static let feedback = Animation.snappy(duration: 0.2)
    static let layout = Animation.smooth(duration: 0.3)
    static let page = Animation.smooth(duration: 0.4)
    static let fade = Animation.easeOut(duration: 0.15)
    static let meter = Animation.smooth(duration: 0.12)
    static let islandOpen = Animation.spring(response: 0.42, dampingFraction: 0.8)
    static let islandClose = Animation.spring(response: 0.45, dampingFraction: 1)
    static let islandContent = Animation.smooth(duration: 0.32)
    static let reduced = Animation.easeInOut(duration: 0.15)
}

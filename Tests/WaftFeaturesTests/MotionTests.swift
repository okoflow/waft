import SwiftUI
import Testing
@testable import WaftFeatures

struct MotionTests {
    @Test(arguments: [false, true])
    func `swaps an animation for the reduced one only when motion is reduced`(reducesMotion: Bool) {
        let animation = Animation.smooth(duration: 1)

        #expect(Motion.adapted(animation, reducesMotion: reducesMotion) == (reducesMotion ? Motion.reduced : animation))
    }

    @Test(arguments: [false, true])
    func `keeps no animation as none`(reducesMotion: Bool) {
        #expect(Motion.adapted(nil, reducesMotion: reducesMotion) == nil)
    }
}

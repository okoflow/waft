import Foundation
import Testing
@testable import WaftPlatform

struct DurationTimeIntervalTests {
    @Test(arguments: [(Duration.seconds(3), 3.0), (.milliseconds(1500), 1.5), (.zero, 0)])
    func `converts a duration to a time interval`(duration: Duration, seconds: TimeInterval) {
        #expect(duration.timeInterval == seconds)
    }
}

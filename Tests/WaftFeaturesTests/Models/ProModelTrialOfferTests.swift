import Foundation
import Testing
@testable import WaftFeatures

struct ProModelTrialOfferTests {
    @Test(arguments: [(0, true), (-10, false)])
    func `offers the trial only while it runs`(daysSinceStart: Double, isOffered: Bool) {
        let pro = ProModel.unlicensed(trialStarted: Date().addingTimeInterval(daysSinceStart * 86400))

        #expect((pro.trialOffer != nil) == isOffered)
    }

    @Test
    func `offers no trial to a license holder`() {
        let pro = ProModel.licensed()

        #expect(pro.license != nil)
        #expect(pro.trialOffer == nil)
    }
}

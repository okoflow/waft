import Foundation
@testable import WaftFeatures

extension ProModel {
    static func unlicensed(trialStarted: Date = Date()) -> ProModel {
        ProModel(
            keyStore: FakeValueStore(),
            trialStore: FakeValueStore(trialStarted),
            checker: FakeLicenseSignatureChecker(signature: Data(), payload: Data()),
            urlOpener: FakeURLOpener(),
        )
    }
}

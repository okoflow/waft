import Foundation
@testable import WaftFeatures

extension ProModel {
    static func licensed() -> ProModel {
        let payload = Data(#"{"email":"ann@example.com"}"#.utf8)
        let signature = Data([1, 2, 3])
        let key = ["WFT1", payload.base64EncodedString(), signature.base64EncodedString()].joined(separator: ".")

        return ProModel(
            keyStore: FakeValueStore(key),
            trialStore: FakeValueStore(Date.distantPast),
            checker: FakeLicenseSignatureChecker(signature: signature, payload: payload),
            urlOpener: FakeURLOpener(),
        )
    }

    static func unlicensed(trialStarted: Date = Date()) -> ProModel {
        ProModel(
            keyStore: FakeValueStore(),
            trialStore: FakeValueStore(trialStarted),
            checker: FakeLicenseSignatureChecker(signature: Data(), payload: Data()),
            urlOpener: FakeURLOpener(),
        )
    }
}

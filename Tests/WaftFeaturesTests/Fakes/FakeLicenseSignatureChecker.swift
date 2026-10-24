import Foundation
import WaftCore

nonisolated struct FakeLicenseSignatureChecker: LicenseSignatureChecking {
    let signature: Data
    let payload: Data

    func isValid(_ signature: Data, for payload: Data) -> Bool {
        guard signature == self.signature else { return false }

        return payload == self.payload
    }
}

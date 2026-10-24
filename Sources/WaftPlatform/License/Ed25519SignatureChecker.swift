package import Foundation
import CryptoKit
import WaftCore

package struct Ed25519SignatureChecker: LicenseSignatureChecking {
    private static let licensePublicKey = "ILFVseTSw4B4Cfx699xDRoFH00t0pg9rX+h6qCEIEO0="

    private let publicKey: Curve25519.Signing.PublicKey

    package init(publicKey: String = Self.licensePublicKey) {
        guard let data = Data(base64Encoded: publicKey),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: data)
        else { preconditionFailure("The license public key isn't a valid Ed25519 key") }

        self.publicKey = key
    }

    package func isValid(_ signature: Data, for payload: Data) -> Bool {
        publicKey.isValidSignature(signature, for: payload)
    }
}

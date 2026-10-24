import CryptoKit
import Foundation
import Testing
import WaftPlatform

struct Ed25519SignatureCheckerTests {
    private static let payload = Data(#"{"id":"lic_7","email":"ann@example.com","name":null,"issued":"2026-10-10"}"#.utf8)

    @Test
    func `accepts a signature made with the matching private key`() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let checker = Ed25519SignatureChecker(publicKey: privateKey.publicKey.rawRepresentation.base64EncodedString())
        let signature = try privateKey.signature(for: Self.payload)

        #expect(checker.isValid(signature, for: Self.payload))
    }

    @Test
    func `rejects a signature from a key other than the license key`() throws {
        let signature = try Curve25519.Signing.PrivateKey().signature(for: Self.payload)

        #expect(!Ed25519SignatureChecker().isValid(signature, for: Self.payload))
    }
}

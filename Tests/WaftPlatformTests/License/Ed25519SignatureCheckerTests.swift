import CryptoKit
import Foundation
import Testing
import WaftCore
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

    @Test(arguments: [(payload, true), (Data(#"{"email":"bob@example.com"}"#.utf8), false)] as [(Data, Bool)])
    func `verifies a license key only over the payload its signature was made for`(sent: Data, isVerified: Bool) throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let checker = Ed25519SignatureChecker(publicKey: privateKey.publicKey.rawRepresentation.base64EncodedString())
        let signature = try privateKey.signature(for: Self.payload)
        let key = try #require(LicenseKey("WFT1.\(sent.base64EncodedString()).\(signature.base64EncodedString())"))

        #expect(key.isVerified(by: checker) == isVerified)
    }

    @Test
    func `rejects a signature from a key other than the license key`() throws {
        let signature = try Curve25519.Signing.PrivateKey().signature(for: Self.payload)

        #expect(!Ed25519SignatureChecker().isValid(signature, for: Self.payload))
    }

    @Test
    func `rejects a signature once the payload changes`() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let checker = Ed25519SignatureChecker(publicKey: privateKey.publicKey.rawRepresentation.base64EncodedString())
        let signature = try privateKey.signature(for: Self.payload)
        let changed = Data(#"{"id":"lic_7","email":"bob@example.com","name":null,"issued":"2026-10-10"}"#.utf8)

        #expect(!checker.isValid(signature, for: changed))
    }

    @Test(arguments: [0, 63])
    func `rejects a signature that is empty or cut short`(length: Int) throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let checker = Ed25519SignatureChecker(publicKey: privateKey.publicKey.rawRepresentation.base64EncodedString())
        let signature = try privateKey.signature(for: Self.payload)

        #expect(!checker.isValid(signature.prefix(length), for: Self.payload))
    }
}

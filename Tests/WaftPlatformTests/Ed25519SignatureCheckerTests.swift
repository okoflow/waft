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
        let signature = try privateKey.signature(for: Self.payload)

        #expect(checker(for: privateKey).isValid(signature, for: Self.payload))
    }

    @Test
    func `rejects a tampered payload`() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let signature = try privateKey.signature(for: Self.payload)
        let tampered = Data(Self.payload.map { $0 == UInt8(ascii: "7") ? UInt8(ascii: "8") : $0 })

        #expect(!checker(for: privateKey).isValid(signature, for: tampered))
    }

    @Test
    func `rejects a signature from another key`() throws {
        let signature = try Curve25519.Signing.PrivateKey().signature(for: Self.payload)

        #expect(!checker(for: Curve25519.Signing.PrivateKey()).isValid(signature, for: Self.payload))
    }

    @Test(arguments: [0, 32, 63])
    func `rejects a truncated signature`(length: Int) throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let signature = try privateKey.signature(for: Self.payload)

        #expect(!checker(for: privateKey).isValid(signature.prefix(length), for: Self.payload))
    }

    @Test
    func `verifies a pasted license key end to end`() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let signature = try privateKey.signature(for: Self.payload)
        let text = "WFT1.\(base64URL(Self.payload)).\(base64URL(signature))"
        let key = try #require(LicenseKey(text))

        #expect(key.license.holder == "ann@example.com")
        #expect(key.isVerified(by: checker(for: privateKey)))
        #expect(!key.isVerified(by: Ed25519SignatureChecker()))
    }

    private func checker(for privateKey: Curve25519.Signing.PrivateKey) -> Ed25519SignatureChecker {
        Ed25519SignatureChecker(publicKey: privateKey.publicKey.rawRepresentation.base64EncodedString())
    }

    private func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

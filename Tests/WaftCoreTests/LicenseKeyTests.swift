import Foundation
import Testing
@testable import WaftCore

struct LicenseKeyTests {
    private static let payload = Data(#"{"id":"lic_42","email":"ann@example.com","name":"Ann Lee","issued":"2026-10-10"}"#.utf8)
    private static let signature = Data((0 ..< 64).map { UInt8($0 * 3 % 256) })

    @Test
    func `reads the license from a key`() throws {
        let key = try #require(LicenseKey("WFT1.\(base64URL(Self.payload)).\(base64URL(Self.signature))"))

        #expect(key.license == License(email: "ann@example.com", name: "Ann Lee"))
        #expect(key.payload == Self.payload)
        #expect(key.signature == Self.signature)
    }

    @Test
    func `reads parts written in the URL-safe base64 alphabet`() throws {
        let key = try #require(LicenseKey("WFT1.\(base64URL(Self.payload)).-_-_"))

        #expect(key.signature == Data([0xFB, 0xFF, 0xBF]))
    }

    @Test
    func `ignores whitespace and line breaks pasted into a key`() throws {
        let key = "WFT1.\(base64URL(Self.payload)).\(base64URL(Self.signature))"
        let pasted = "  " + key.prefix(20) + "\n " + key.dropFirst(20).prefix(30) + "\t" + key.dropFirst(50) + "\n"
        let license = try #require(LicenseKey(pasted)).license

        #expect(license.email == "ann@example.com")
    }

    @Test(arguments: [
        "",
        "WFT1",
        "WFT1.e30",
        "WFT1.e30.AAAA.AAAA",
        "WFT1.@@@@.AAAA",
        "WFT1.e30.AAAA",
        "WFT1.bm90IGpzb24.AAAA",
        "WFT1.eyJpZCI6IjEifQ.AAAA",
    ])
    func `rejects malformed keys`(text: String) {
        #expect(LicenseKey(text) == nil)
    }

    @Test(arguments: ["wft1", "WFT2", ""])
    func `rejects a key with another prefix`(prefix: String) {
        #expect(LicenseKey("\(prefix).\(base64URL(Self.payload)).\(base64URL(Self.signature))") == nil)
    }

    @Test
    func `verifies the signature over the payload`() throws {
        let key = try #require(LicenseKey("WFT1.\(base64URL(Self.payload)).\(base64URL(Self.signature))"))

        #expect(key.isVerified(by: FakeLicenseSignatureChecker(signature: Self.signature, payload: Self.payload)))
        #expect(!key.isVerified(by: FakeLicenseSignatureChecker(signature: Data(), payload: Self.payload)))
    }

    private func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private struct FakeLicenseSignatureChecker: LicenseSignatureChecking {
    let signature: Data
    let payload: Data

    func isValid(_ signature: Data, for payload: Data) -> Bool {
        guard signature == self.signature else { return false }

        return payload == self.payload
    }
}

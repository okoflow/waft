import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct ProModelTests {
    private nonisolated static let payload = Data(#"{"email":"ann@example.com","name":"Ann Lee"}"#.utf8)
    private nonisolated static let signature = Data([1, 2, 3, 4])
    private nonisolated static let key = licenseKey(signature: signature)
    private nonisolated static let forgedKey = licenseKey(signature: Data([9, 9]))

    private nonisolated static func licenseKey(signature: Data) -> String {
        "WFT1.\(base64URL(payload)).\(base64URL(signature))"
    }

    private nonisolated static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    @Test
    func `activates a valid key from the draft`() {
        let keyStore = FakeValueStore<String>()
        let pro = model(keyStore: keyStore)
        pro.draft = "  \(Self.key)\n"
        pro.activateDraft()

        #expect(pro.license?.holder == "Ann Lee")
        #expect(keyStore.value == Self.key)
        #expect(pro.draft.isEmpty)
        #expect(pro.activationProblem == nil)
        #expect(pro.isUnlocked)
    }

    @Test(arguments: [("WFT1.not-a-key", ProModel.ActivationProblem.unreadable), (forgedKey, .invalid)])
    func `reports a draft that is not a valid key`(draft: String, problem: ProModel.ActivationProblem) {
        let keyStore = FakeValueStore<String>()
        let pro = model(keyStore: keyStore)
        pro.draft = draft
        pro.activateDraft()

        #expect(pro.activationProblem == problem)
        #expect(pro.license == nil)
        #expect(keyStore.value == nil)
        #expect(pro.showsLicenseSection)

        pro.draft += " "

        #expect(pro.activationProblem == nil)
    }

    @Test(arguments: [(key, String?.some("ann@example.com")), (forgedKey, nil)])
    func `loads only a verified stored key`(stored: String, email: String?) {
        #expect(model(keyStore: FakeValueStore(stored)).license?.email == email)
    }

    @Test
    func `removes the key on deactivation`() {
        let keyStore = FakeValueStore(Self.key)
        let pro = model(keyStore: keyStore)
        pro.deactivate()

        #expect(pro.license == nil)
        #expect(keyStore.value == nil)
    }

    @Test(.enabled(if: ProAccess.isFreeDuringBeta))
    func `starts no trial and hides the license section during the beta`() {
        let trialStore = FakeValueStore<Date>()
        let pro = model(trialStore: trialStore)

        #expect(trialStore.value == nil)
        #expect(!pro.showsLicenseSection)
    }

    @Test
    func `opens the purchase page`() {
        let urlOpener = FakeURLOpener()
        model(urlOpener: urlOpener).purchase()

        #expect(urlOpener.opened.map(\.absoluteString) == ["https://waft.okoflow.com/pro"])
    }

    private func model(
        keyStore: FakeValueStore<String> = FakeValueStore(),
        trialStore: FakeValueStore<Date> = FakeValueStore(),
        urlOpener: FakeURLOpener = FakeURLOpener(),
    ) -> ProModel {
        ProModel(
            keyStore: keyStore,
            trialStore: trialStore,
            checker: FakeLicenseSignatureChecker(signature: Self.signature, payload: Self.payload),
            urlOpener: urlOpener,
        )
    }
}

private nonisolated struct FakeLicenseSignatureChecker: LicenseSignatureChecking {
    let signature: Data
    let payload: Data

    func isValid(_ signature: Data, for payload: Data) -> Bool {
        guard signature == self.signature else { return false }

        return payload == self.payload
    }
}

private final class FakeURLOpener: URLOpener {
    private(set) var opened: [URL] = []

    func open(_ url: URL) {
        opened.append(url)
    }

    func reveal(_: URL) {}
}

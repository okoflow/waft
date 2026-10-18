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
    }

    @Test(arguments: [("WFT1.not-a-key", ProModel.ActivationProblem.unreadable), (forgedKey, .invalid)])
    func `reports a draft that is not a valid key until the draft changes`(draft: String, problem: ProModel.ActivationProblem) {
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
    func `reports each change of access on activation and deactivation`() {
        var changeCount = 0
        let pro = model()
        pro.onAccessChange = { changeCount += 1 }
        pro.draft = Self.key
        pro.activateDraft()

        #expect(changeCount == 1)

        pro.draft = Self.forgedKey
        pro.activateDraft()

        #expect(changeCount == 1)

        pro.deactivate()

        #expect(changeCount == 2)
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

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `saves the trial start on first launch once the beta ends`() {
        let trialStore = FakeValueStore<Date>()
        _ = model(trialStore: trialStore)

        #expect(trialStore.value != nil)
    }

    @Test
    func `ends the trial from today when the stored start lies in the future`() {
        let pro = model(trialStore: FakeValueStore(Date().addingTimeInterval(30 * 86400)))

        #expect(pro.trialEnds == ProAccess.trialEnd(startedOn: Date(), now: Date()))
    }

    @Test(.enabled(if: ProAccess.isFreeDuringBeta))
    func `locks no mode and no speech model during the beta`() {
        let pro = model(trialStore: FakeValueStore(Date.distantPast))

        #expect(!(Mode.builtIn + [.custom(UUID())]).contains { pro.locks($0) })
        #expect(!SpeechModel.allCases.contains { pro.locks($0) })
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `locks the AI modes and the accurate model without a license once the beta ends`() {
        let pro = model(trialStore: FakeValueStore(Date.distantPast))
        let custom = Mode.custom(UUID())

        #expect((Mode.builtIn + [custom]).filter { pro.locks($0) } == [.clean, .formal, .translate, custom])
        #expect(SpeechModel.allCases.filter { pro.locks($0) } == [.accurate])
    }

    private func model(
        keyStore: FakeValueStore<String> = FakeValueStore(),
        trialStore: FakeValueStore<Date> = FakeValueStore(),
    ) -> ProModel {
        ProModel(
            keyStore: keyStore,
            trialStore: trialStore,
            checker: FakeLicenseSignatureChecker(signature: Self.signature, payload: Self.payload),
            urlOpener: FakeURLOpener(),
        )
    }
}

import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct ProModelTests {
    private nonisolated static let payload = Data(#"{"email":"ann@example.com","name":"Ann Lee"}"#.utf8)
    private nonisolated static let signature = Data([1, 2, 3, 4])
    private nonisolated static let key = licenseKey(signature: signature)
    private nonisolated static let forgedKey = licenseKey(signature: Data([9, 9]))
    private nonisolated static let firstLaunch = Date(timeIntervalSince1970: 1_800_000_000)

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

    @Test
    func `reports a key that cannot be saved and keeps it in the field`() {
        let keyStore = FakeValueStore<String>(failsSaving: true)
        let pro = model(keyStore: keyStore)

        pro.draft = Self.key
        pro.activateDraft()

        #expect(pro.license == nil)
        #expect(pro.activationProblem == .notSaved)
        #expect(pro.draft == Self.key)
        #expect(keyStore.value == nil)
    }

    @Test
    func `keeps the license when its key cannot be removed`() {
        let keyStore = FakeValueStore(Self.key, failsDeleting: true)
        let pro = model(keyStore: keyStore)

        pro.deactivate()

        #expect(pro.license?.holder == "Ann Lee")
        #expect(keyStore.value == Self.key)
    }

    @Test
    func `reports a key that cannot be removed until a removal works`() {
        let keyStore = FakeValueStore(Self.key, failsDeleting: true)
        let pro = model(keyStore: keyStore)

        #expect(!pro.hasFailedRemoval)

        pro.deactivate()

        #expect(pro.hasFailedRemoval)

        keyStore.failsDeleting = false
        pro.deactivate()

        #expect(!pro.hasFailedRemoval)
        #expect(pro.license == nil)
    }

    @Test(arguments: [(nil, firstLaunch), (Date.distantPast, .distantPast)] as [(Date?, Date)])
    func `saves the trial start on first launch and keeps it on later launches`(saved: Date?, kept: Date) {
        let trialStore = FakeValueStore(saved)
        _ = model(trialStore: trialStore, now: Self.firstLaunch)

        #expect(trialStore.value == kept)
    }

    @Test
    func `counts the last day of the trial from the stored start`() throws {
        let started = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 23)))
        let lastDay = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 1)))
        let pro = model(trialStore: FakeValueStore(started))

        #expect(pro.trialLastDay == lastDay)
    }

    @Test
    func `locks no mode and no speech model during the trial`() {
        let pro = model()

        #expect(!(Mode.builtIn + [.custom(UUID())]).contains { pro.locks($0) })
        #expect(!SpeechModel.allCases.contains { pro.locks($0) })
    }

    @Test
    func `locks the AI modes and the accurate model once the trial ends`() {
        let pro = model(trialStore: FakeValueStore(Date.distantPast))
        let custom = Mode.custom(UUID())

        #expect((Mode.builtIn + [custom]).filter { pro.locks($0) } == [.clean, .formal, .translate, custom])
        #expect(SpeechModel.allCases.filter { pro.locks($0) } == [.accurate])
    }

    @Test
    func `unlocks everything with a key activated after the trial and locks it again without the key`() {
        let pro = model(trialStore: FakeValueStore(Date.distantPast))

        pro.draft = Self.key
        pro.activateDraft()

        #expect(pro.isUnlocked)
        #expect(!Mode.builtIn.contains { pro.locks($0) })
        #expect(!SpeechModel.allCases.contains { pro.locks($0) })

        pro.deactivate()

        #expect(!pro.isUnlocked)
        #expect(pro.locks(.clean))
        #expect(pro.locks(.accurate))
    }

    @Test
    func `tells an observer of the access when the last day of the trial ends`() async {
        let lastDay = Calendar.current.startOfDay(for: Self.firstLaunch) + 12 * 3600
        var now = lastDay
        let dayChangeMonitor = FakeDayChangeMonitor()
        let pro = ProModel.unlicensed(trialStarted: lastDay - 2 * 86400, dayChangeMonitor: dayChangeMonitor, now: { now })
        let observer = AccessObserver(of: pro)

        #expect(pro.access.status == .trial)

        now += 86400
        dayChangeMonitor.changeDay()

        #expect(await Poll.until(timeout: .seconds(5)) { observer.isNotified })
        #expect(pro.access.status == .expired)
    }

    @Test
    func `opens the purchase page`() {
        let urlOpener = FakeURLOpener()
        let pro = model(urlOpener: urlOpener)

        pro.purchase()

        #expect(urlOpener.opened == [URL(string: "https://waft.okoflow.com/pro")])
    }

    private func model(
        keyStore: FakeValueStore<String> = FakeValueStore(),
        trialStore: FakeValueStore<Date> = FakeValueStore(),
        urlOpener: FakeURLOpener = FakeURLOpener(),
        now: Date = Date(),
    ) -> ProModel {
        ProModel(
            keyStore: keyStore,
            trialStore: trialStore,
            checker: FakeLicenseSignatureChecker(signature: Self.signature, payload: Self.payload),
            urlOpener: urlOpener,
            dayChangeMonitor: FakeDayChangeMonitor(),
            now: { now },
        )
    }
}

private final class AccessObserver {
    private(set) var isNotified = false

    init(of pro: ProModel) {
        withObservationTracking { _ = pro.access } onChange: { [self] in
            MainActor.assumeIsolated { isNotified = true }
        }
    }
}

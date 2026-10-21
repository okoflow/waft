import Foundation
import Observation
import os
import WaftCore

@Observable
final class ProModel {
    enum ActivationProblem: Equatable {
        case unreadable
        case invalid
    }

    static let price = (Decimal(1399) / 100).formatted(.currency(code: "USD"))

    private static let purchaseURL = URL(literal: "https://waft.okoflow.com/pro")

    @ObservationIgnored var onAccessChange: (() -> Void)?

    private(set) var license: License?
    private(set) var activationProblem: ActivationProblem?

    var draft = "" {
        didSet { activationProblem = nil }
    }

    private var hasTriedActivation = false

    private let keyStore: any ValueStore<String>
    private let checker: any LicenseSignatureChecking
    private let urlOpener: any URLOpener
    private let trialStarted: Date

    var trialEnds: Date {
        ProAccess.trialEnd(startedOn: trialStarted, now: Date())
    }

    var access: ProAccess {
        ProAccess(license: license, trialStarted: trialStarted, now: Date())
    }

    var isUnlocked: Bool {
        access.isUnlocked
    }

    var showsLicenseSection: Bool {
        guard license == nil, !hasTriedActivation else { return true }

        return !ProAccess.isFreeDuringBeta
    }

    var canActivateDraft: Bool {
        !draft.isBlank
    }

    init(
        keyStore: any ValueStore<String>,
        trialStore: any ValueStore<Date>,
        checker: any LicenseSignatureChecking,
        urlOpener: any URLOpener,
    ) {
        self.keyStore = keyStore
        self.checker = checker
        self.urlOpener = urlOpener
        trialStarted = Self.trialStart(in: trialStore)
        license = Self.storedLicense(in: keyStore, checker: checker)
    }

    private static func trialStart(in store: any ValueStore<Date>) -> Date {
        if let started = store.read() {
            return started
        }

        let now = Date()

        if !ProAccess.isFreeDuringBeta {
            store.write(now)
        }

        return now
    }

    private static func storedLicense(in store: any ValueStore<String>, checker: any LicenseSignatureChecking) -> License? {
        guard let text = store.read() else { return nil }
        guard let key = LicenseKey(text), key.isVerified(by: checker) else {
            Logger.settings.error("The stored license key isn't valid")

            return nil
        }

        return key.license
    }

    func activateDraft() {
        hasTriedActivation = true

        guard let key = LicenseKey(draft) else {
            activationProblem = .unreadable

            return
        }
        guard key.isVerified(by: checker) else {
            activationProblem = .invalid

            return
        }

        keyStore.write(draft.trimmingCharacters(in: .whitespacesAndNewlines))
        license = key.license
        draft = ""

        onAccessChange?()
    }

    func deactivate() {
        keyStore.remove()
        license = nil

        onAccessChange?()
    }

    func locks(_ mode: Mode) -> Bool {
        guard mode.usesAI else { return false }

        return !isUnlocked
    }

    func locks(_ model: SpeechModel) -> Bool {
        guard model.needsPro else { return false }

        return !isUnlocked
    }

    func purchase() {
        urlOpener.open(Self.purchaseURL)
    }
}

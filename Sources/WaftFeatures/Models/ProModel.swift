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

    static let price = "$13.99"

    private static let purchaseURL = URL(literal: "https://waft.okoflow.com/pro")

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
        ProAccess.trialEnd(startedOn: min(trialStarted, Date()))
    }

    var access: ProAccess {
        ProAccess(license: license, trialStarted: trialStarted, now: Date())
    }

    var isUnlocked: Bool {
        access.isUnlocked
    }

    var showsLicenseSection: Bool {
        license != nil || hasTriedActivation || !ProAccess.isFreeDuringBeta
    }

    var canActivateDraft: Bool {
        !trimmedDraft.isEmpty
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
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

        keyStore.write(trimmedDraft)
        license = key.license
        draft = ""
    }

    func deactivate() {
        keyStore.remove()
        license = nil
    }

    func locks(_ mode: Mode) -> Bool {
        mode.usesAI && !isUnlocked
    }

    func locks(_ model: SpeechModel) -> Bool {
        model.needsPro && !isUnlocked
    }

    func purchase() {
        urlOpener.open(Self.purchaseURL)
    }
}

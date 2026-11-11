import Foundation
import Observation
import os
import WaftCore

@Observable
final class ProModel {
    enum ActivationProblem: Equatable {
        case unreadable
        case invalid
        case notSaved
    }

    static let price = (Decimal(1399) / 100).formatted(.currency(code: "USD"))

    private static let purchaseURL = URL(literal: "https://waft.okoflow.com/pro")

    @ObservationIgnored var onAccessChange: (() -> Void)?

    private(set) var license: License?
    private(set) var activationProblem: ActivationProblem?
    private(set) var hasFailedRemoval = false

    var draft = "" {
        didSet { activationProblem = nil }
    }

    private let keyStore: any ValueStore<String>
    private let checker: any LicenseSignatureChecking
    private let urlOpener: any URLOpener
    private let trialStarted: Date
    private let now: () -> Date

    var trialLastDay: Date {
        ProAccess.trialLastDay(startedOn: trialStarted, now: now())
    }

    var access: ProAccess {
        ProAccess(license: license, trialStarted: trialStarted, now: now())
    }

    var isUnlocked: Bool {
        access.isUnlocked
    }

    var canActivateDraft: Bool {
        !draft.isBlank
    }

    init(
        keyStore: any ValueStore<String>,
        trialStore: any ValueStore<Date>,
        checker: any LicenseSignatureChecking,
        urlOpener: any URLOpener,
        now: @escaping () -> Date = Date.init,
    ) {
        self.keyStore = keyStore
        self.checker = checker
        self.urlOpener = urlOpener
        self.now = now
        trialStarted = Self.trialStart(in: trialStore, now: now())
        license = Self.storedLicense(in: keyStore, checker: checker)
    }

    private static func trialStart(in store: any ValueStore<Date>, now: Date) -> Date {
        if let started = store.read() {
            return started
        }

        store.write(now)

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
        guard let key = LicenseKey(draft) else {
            activationProblem = .unreadable

            return
        }
        guard key.isVerified(by: checker) else {
            activationProblem = .invalid

            return
        }
        guard keyStore.write(draft.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            activationProblem = .notSaved

            return
        }

        license = key.license
        draft = ""

        onAccessChange?()
    }

    func deactivate() {
        hasFailedRemoval = !keyStore.remove()
        guard !hasFailedRemoval else { return }

        license = nil

        onAccessChange?()
    }

    func locks(_ mode: Mode) -> Bool {
        guard mode.usesAI else { return false }

        return !isUnlocked
    }

    func locks(_ model: SpeechModel) -> Bool {
        guard model.needsWaftPlus else { return false }

        return !isUnlocked
    }

    func purchase() {
        urlOpener.open(Self.purchaseURL)
    }
}

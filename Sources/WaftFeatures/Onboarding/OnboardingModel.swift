import Observation
import WaftCore

@Observable
final class OnboardingModel {
    enum Step: Int, CaseIterable {
        case welcome
        case microphone
        case accessibility
        case practice
        case usage
        case done

        var permission: Permission? {
            switch self {
            case .welcome, .practice, .usage, .done: nil
            case .microphone: .microphone
            case .accessibility: .accessibility
            }
        }
    }

    private(set) var step = Step.welcome {
        didSet { visitedSteps.insert(step) }
    }

    var practiceText = ""

    @ObservationIgnored var onFinish: (() -> Void)?
    @ObservationIgnored private(set) var advanceTask: Task<Void, Never>?

    private var isResuming = false
    private var asksAboutUsage: Bool
    private var visitedSteps: Set<Step> = [.welcome]

    private let permissions: PermissionMonitor
    private let settings: SettingsModel
    private let grantedPause: Duration
    private let waitForPause: (Duration) async -> Bool

    var steps: [Step] {
        Step.allCases.filter(lists)
    }

    var canGoBack: Bool {
        previousStep != nil
    }

    var pendingStatus: PermissionStatus? {
        guard let pendingPermission else { return nil }

        return permissions.status(of: pendingPermission)
    }

    private var pendingPermission: Permission? {
        guard let permission = step.permission, isMissing(permission) else { return nil }

        return permission
    }

    private var previousStep: Step? {
        Step.allCases.prefix { $0.rawValue < step.rawValue }.last(where: shows)
    }

    private var nextStep: Step? {
        Step.allCases.drop { $0.rawValue <= step.rawValue }.first(where: shows)
    }

    init(
        permissions: PermissionMonitor,
        settings: SettingsModel,
        grantedPause: Duration = .milliseconds(600),
        waitForPause: @escaping (Duration) async -> Bool = { await Task.slept(for: $0) },
    ) {
        self.permissions = permissions
        self.settings = settings
        asksAboutUsage = settings.settings.usageSharing == .undecided
        self.grantedPause = grantedPause
        self.waitForPause = waitForPause
    }

    func goBack() {
        guard let previousStep else { return }

        cancelAdvance()
        step = previousStep
    }

    func proceed() async {
        guard let pendingPermission else {
            advance()

            return
        }

        await permissions.request(pendingPermission)
    }

    func answerUsage(shares: Bool) {
        settings.sharesUsage = shares

        advance()
    }

    func resume() {
        cancelAdvance()
        isResuming = true
        asksAboutUsage = settings.settings.usageSharing == .undecided

        guard let firstStep = Step.allCases.first(where: shows) else { return }

        visitedSteps = []
        step = firstStep
    }

    func finish() {
        cancelAdvance()
        onFinish?()
    }

    func permissionsDidChange() {
        cancelAdvance()

        guard let permission = step.permission, !isMissing(permission) else { return }

        let grantedStep = step
        let pause = grantedPause

        advanceTask = Task { [weak self, waitForPause] in
            guard await waitForPause(pause), !Task.isCancelled, let self, step == grantedStep else { return }

            permissions.refresh()

            guard !Task.isCancelled, !isMissing(permission) else { return }

            advanceTask = nil
            advance()
        }
    }

    func reset() {
        cancelAdvance()
        step = .welcome
        visitedSteps = [.welcome]
        practiceText = ""
        isResuming = false
        asksAboutUsage = settings.settings.usageSharing == .undecided
    }

    private func isMissing(_ permission: Permission) -> Bool {
        !permissions.status(of: permission).isGranted
    }

    private func lists(_ step: Step) -> Bool {
        guard !visitedSteps.contains(step) else { return true }

        return shows(step)
    }

    private func shows(_ step: Step) -> Bool {
        switch step {
        case .welcome, .practice, .done: !isResuming
        case .microphone: isMissing(.microphone)
        case .accessibility: isMissing(.accessibility)
        case .usage: asksAboutUsage
        }
    }

    private func advance() {
        cancelAdvance()

        guard let nextStep else {
            finish()

            return
        }

        step = nextStep
    }

    private func cancelAdvance() {
        advanceTask?.cancel()
        advanceTask = nil
    }
}

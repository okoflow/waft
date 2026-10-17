import Observation
import WaftCore

@Observable
final class OnboardingModel {
    enum Step: Int, CaseIterable {
        case welcome
        case microphone
        case accessibility
        case practice
        case done

        var permission: Permission? {
            switch self {
            case .microphone: .microphone
            case .accessibility: .accessibility
            case .welcome, .practice, .done: nil
            }
        }
    }

    private(set) var step = Step.welcome
    var practiceText = ""

    @ObservationIgnored var onFinish: (() -> Void)?
    @ObservationIgnored private(set) var advanceTask: Task<Void, Never>?

    private var isResuming = false

    private let permissions: PermissionMonitor
    private let grantedPause: Duration
    private let waitForPause: (Duration) async -> Bool

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
        Step.allCases.last { $0.rawValue < step.rawValue && shows($0) }
    }

    private var nextStep: Step? {
        Step.allCases.first { $0.rawValue > step.rawValue && shows($0) }
    }

    init(
        permissions: PermissionMonitor,
        grantedPause: Duration = .milliseconds(600),
        waitForPause: @escaping (Duration) async -> Bool = { await Task.slept(for: $0) },
    ) {
        self.permissions = permissions
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

    func resume() {
        cancelAdvance()
        isResuming = true

        guard let firstStep = Step.allCases.first(where: shows) else { return }

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

            guard !Task.isCancelled, step == grantedStep, !isMissing(permission) else { return }

            advanceTask = nil
            advance()
        }
    }

    func reset() {
        cancelAdvance()
        step = .welcome
        practiceText = ""
        isResuming = false
    }

    private func isMissing(_ permission: Permission) -> Bool {
        !permissions.status(of: permission).isGranted
    }

    private func shows(_ step: Step) -> Bool {
        guard let permission = step.permission else { return !isResuming }

        return isMissing(permission)
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

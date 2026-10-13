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

    private var isResuming = false

    private let permissions: PermissionMonitor
    private let grantedPause: Duration

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

    init(permissions: PermissionMonitor, grantedPause: Duration = .milliseconds(600)) {
        self.permissions = permissions
        self.grantedPause = grantedPause
    }

    func goBack() {
        guard let previousStep else { return }

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
        isResuming = true

        guard let firstStep = Step.allCases.first(where: shows) else { return }

        step = firstStep
    }

    func finish() {
        onFinish?()
    }

    func permissionsDidChange() {
        guard let permission = step.permission, !isMissing(permission) else { return }

        let grantedStep = step
        let pause = grantedPause

        Task { [weak self] in
            guard await Task.slept(for: pause), let self, step == grantedStep else { return }

            advance()
        }
    }

    func reset() {
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
        guard let nextStep else {
            finish()

            return
        }

        step = nextStep
    }
}

import WaftCore

final class FakePermissionProvider: PermissionProvider {
    private(set) var requests: [Permission] = []

    private var statuses: [Permission: PermissionStatus]
    private let answers: [Permission: PermissionStatus]

    init(_ statuses: [Permission: PermissionStatus], answers: [Permission: PermissionStatus] = [:]) {
        self.statuses = statuses
        self.answers = answers
    }

    func status(of permission: Permission) -> PermissionStatus {
        statuses[permission, default: .notDetermined]
    }

    func request(_ permission: Permission) {
        requests.append(permission)
        statuses[permission] = answers[permission, default: status(of: permission)]
    }
}

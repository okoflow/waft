import Foundation
import Observation
import WaftCore

@Observable
final class PermissionMonitor {
    private static let pollInterval: TimeInterval = 1

    @ObservationIgnored var onChange: (() -> Void)?

    private var statuses: [Permission: PermissionStatus] = [:]

    @ObservationIgnored private var timer: Timer?

    private let provider: any PermissionProvider

    var allGranted: Bool {
        Permission.allCases.allSatisfy { status(of: $0).isGranted }
    }

    init(provider: any PermissionProvider) {
        self.provider = provider

        refresh()
    }

    func status(of permission: Permission) -> PermissionStatus {
        statuses[permission, default: .notDetermined]
    }

    func request(_ permission: Permission) async {
        await provider.request(permission)

        refresh()
    }

    func startMonitoring() {
        guard timer == nil else { return }

        timer = .scheduledInCommonModes(every: Self.pollInterval, repeats: true) { [weak self] in
            self?.refresh()
        }
    }

    func refresh() {
        let latest = Dictionary(uniqueKeysWithValues: Permission.allCases.map { ($0, provider.status(of: $0)) })
        guard latest != statuses else { return }

        statuses = latest

        onChange?()
    }
}

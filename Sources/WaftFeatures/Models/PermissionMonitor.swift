import Foundation
import Observation
import WaftCore

@Observable
final class PermissionMonitor {
    @ObservationIgnored var onChange: (() -> Void)?

    private var statuses: [Permission: PermissionStatus] = [:]

    @ObservationIgnored private var timer: Timer?

    private let provider: any PermissionProvider
    private let pollInterval: TimeInterval
    private let grantedPollInterval: TimeInterval

    var allGranted: Bool {
        Permission.allCases.allSatisfy { status(of: $0).isGranted }
    }

    private var currentPollInterval: TimeInterval {
        allGranted ? grantedPollInterval : pollInterval
    }

    init(provider: any PermissionProvider, pollInterval: TimeInterval = 1, grantedPollInterval: TimeInterval = 30) {
        self.provider = provider
        self.pollInterval = pollInterval
        self.grantedPollInterval = grantedPollInterval

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

        schedulePolling()
    }

    func refresh() {
        let latest = Dictionary(uniqueKeysWithValues: Permission.allCases.map { ($0, provider.status(of: $0)) })
        guard latest != statuses else { return }

        statuses = latest

        onChange?()
    }

    private func schedulePolling() {
        timer?.invalidate()
        timer = .scheduledInCommonModes(every: currentPollInterval, repeats: true) { [weak self] in
            self?.poll()
        }
    }

    private func poll() {
        refresh()

        guard let timer, timer.timeInterval != currentPollInterval else { return }

        schedulePolling()
    }
}

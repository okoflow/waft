import Foundation
import Observation
import os
import WaftCore

@Observable
final class KeyMonitorController {
    enum Status: Equatable {
        case starting
        case ready
        case unavailable
    }

    private(set) var status = Status.starting

    @ObservationIgnored private var retryTimer: Timer?
    @ObservationIgnored private var healthCheckTimer: Timer?

    private let monitor: any KeyEventMonitor
    private let retryInterval: TimeInterval
    private let healthCheckInterval: TimeInterval

    init(monitor: any KeyEventMonitor, retryInterval: TimeInterval = 2, healthCheckInterval: TimeInterval = 5) {
        self.monitor = monitor
        self.retryInterval = retryInterval
        self.healthCheckInterval = healthCheckInterval
    }

    func start() {
        retryTimer?.invalidate()

        guard monitor.start() else {
            status = .unavailable
            retryTimer = .scheduledInCommonModes(every: retryInterval, repeats: false) { [weak self] in
                self?.start()
            }

            return
        }

        status = .ready

        watchHealth()
    }

    func permissionsDidChange() {
        guard status != .ready else { return }

        start()
    }

    private func watchHealth() {
        guard healthCheckTimer == nil else { return }

        healthCheckTimer = .scheduledInCommonModes(every: healthCheckInterval, repeats: true) { [weak self] in
            self?.restartIfStopped()
        }
    }

    private func restartIfStopped() {
        guard status == .ready, !monitor.isRunning else { return }

        Logger.dictation.notice("The key listener stopped; starting it again")

        start()
    }
}

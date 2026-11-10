import Foundation
import os
import WaftCore

final class UsageReporter {
    private static let interval = Duration.seconds(6 * 60 * 60)

    private var log: UsageLog?
    private var reporting: Task<Void, Never>?

    private let store: any ValueStore<UsageLog>
    private let sender: any UsageReportSender
    private let settings: SettingsModel
    private let pro: ProModel
    private let host: UsageHost?
    private let waitForInterval: (Duration) async -> Bool

    init(
        store: any ValueStore<UsageLog>,
        sender: any UsageReportSender,
        settings: SettingsModel,
        pro: ProModel,
        host: UsageHost?,
        waitForInterval: @escaping (Duration) async -> Bool = { await Task.slept(for: $0) },
    ) {
        self.store = store
        self.sender = sender
        self.settings = settings
        self.pro = pro
        self.host = host
        self.waitForInterval = waitForInterval
    }

    func start() {
        reporting?.cancel()
        reporting = nil

        guard settings.settings.usageSharing == .allowed, host != nil else {
            forgetLog()

            return
        }

        log = store.read(default: UsageLog(installation: UUID()))

        reporting = Task { [weak self, waitForInterval] in
            repeat {
                await self?.sendUnsentDays()
            } while await waitForInterval(Self.interval)
        }
    }

    func record(_ event: UsageEvent) {
        guard var current = log else { return }

        current.record(event, on: Date())

        keep(current)
    }

    private func sendUnsentDays() async {
        guard var current = log else { return }

        current.startDay(on: Date())

        keep(current)

        for day in current.unsentDays {
            guard await send(day) else { return }
        }
    }

    private func send(_ day: String) async -> Bool {
        guard let host, let log, let counts = log.days[day]?.counts else { return false }

        let report = UsageReport(
            installation: log.installation,
            day: day,
            counts: counts,
            host: host,
            settings: settings.settings,
            access: pro.access,
        )

        do {
            try await sender.send(report)
        } catch {
            Logger.usage.error("Couldn't send the usage report: \(error.logDescription, privacy: .public)")

            return false
        }

        guard !Task.isCancelled, var current = self.log else { return false }

        current.markSent(day, with: counts)

        keep(current)

        return true
    }

    private func keep(_ changed: UsageLog) {
        log = changed
        store.write(changed)
    }

    private func forgetLog() {
        log = nil
        store.remove()
    }
}

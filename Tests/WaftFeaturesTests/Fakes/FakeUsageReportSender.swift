import Foundation
import os
import WaftCore

final nonisolated class FakeUsageReportSender: UsageReportSender {
    private let fails: Bool
    private let holdsReports: Bool
    private let sent = OSAllocatedUnfairLock(initialState: [UsageReport]())
    private let released = OSAllocatedUnfairLock(initialState: false)

    var reports: [UsageReport] {
        sent.withLock { $0 }
    }

    init(fails: Bool = false, holdsReports: Bool = false) {
        self.fails = fails
        self.holdsReports = holdsReports
    }

    func release() {
        released.withLock { $0 = true }
    }

    func send(_ report: UsageReport) async throws {
        guard !fails else { throw URLError(.notConnectedToInternet) }

        sent.withLock { $0.append(report) }

        if holdsReports {
            await Poll.until(timeout: .seconds(5)) { released.withLock { $0 } }
        }
    }
}

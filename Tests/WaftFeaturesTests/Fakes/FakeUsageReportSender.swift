import Foundation
import os
import WaftCore

final nonisolated class FakeUsageReportSender: UsageReportSender {
    private let fails: Bool
    private let sent = OSAllocatedUnfairLock(initialState: [UsageReport]())

    var reports: [UsageReport] {
        sent.withLock { $0 }
    }

    init(fails: Bool = false) {
        self.fails = fails
    }

    func send(_ report: UsageReport) throws {
        guard !fails else { throw URLError(.notConnectedToInternet) }

        sent.withLock { $0.append(report) }
    }
}

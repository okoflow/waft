package protocol UsageReportSender: Sendable {
    func send(_ report: UsageReport) async throws
}

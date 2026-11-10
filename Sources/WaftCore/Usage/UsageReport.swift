package import Foundation

package struct UsageReport: Encodable, Equatable, Sendable {
    let installation: String
    let day: String
    let appVersion: String
    let systemVersion: String
    let language: String
    let speechModel: String
    let provider: String
    let license: String
    let counts: UsageCounts

    package init(installation: UUID, day: String, counts: UsageCounts, host: UsageHost, settings: Settings, access: ProAccess) {
        self.installation = installation.uuidString.lowercased()
        self.day = day
        appVersion = host.appVersion
        systemVersion = host.systemVersion
        language = host.language
        speechModel = settings.speechModel.rawValue
        provider = settings.modelProvider.rawValue
        license = Self.name(of: access.status)
        self.counts = counts
    }

    private static func name(of status: ProAccess.Status) -> String {
        switch status {
        case .licensed: "licensed"
        case .beta: "beta"
        case .trial: "trial"
        case .expired: "expired"
        }
    }
}

import Foundation
import WaftCore

extension UsageHost {
    static var current: Self? {
        guard let appVersion = AppVersion.number, let language = Bundle.main.preferredLocalizations.first else { return nil }

        let system = ProcessInfo.processInfo.operatingSystemVersion

        return Self(appVersion: appVersion, systemVersion: "\(system.majorVersion).\(system.minorVersion)", language: language)
    }
}

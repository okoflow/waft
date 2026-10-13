import Foundation

enum AppVersion {
    static var title: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return String(localized: "Development build")
        }

        return String(localized: "Version \(version)")
    }
}

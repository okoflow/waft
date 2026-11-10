import Foundation

enum AppVersion {
    static var number: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static var title: String {
        guard let number else { return String(localized: "Development build") }

        return String(localized: "Version \(number)")
    }
}

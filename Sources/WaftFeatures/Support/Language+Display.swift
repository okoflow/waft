import Foundation
import WaftCore

extension Language {
    static let interfaceLocale = Locale(identifier: interfaceLanguage)
    static let allByDisplayName = allCases.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }

    private static var interfaceLanguage: String {
        guard let identifier = Bundle.main.preferredLocalizations.first else { return "en" }

        return identifier
    }

    var displayName: String {
        inlineName.sentenceCased()
    }

    var inlineName: String {
        guard let localized = Self.interfaceLocale.localizedString(forLanguageCode: localeCode) else { return name }

        return localized
    }

    static func inlineList(_ languages: [Language]) -> String {
        let names = languages.map(\.inlineName)
        let formatter = ListFormatter()
        formatter.locale = interfaceLocale

        guard let list = formatter.string(from: names) else { return names.joined(separator: ", ") }

        return list
    }
}

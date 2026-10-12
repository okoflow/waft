import Foundation
import WaftCore

extension String {
    func sentenceCased(in locale: Locale = Language.interfaceLocale) -> String {
        prefix(1).uppercased(with: locale) + dropFirst()
    }
}

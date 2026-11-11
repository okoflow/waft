import SwiftUI
import WaftCore

extension ProGateBanner {
    static func aiModes(showPro: @escaping () -> Void) -> ProGateBanner {
        ProGateBanner(
            title: .verbatim(String(localized: "AI modes need Waft+").sentenceCased()),
            detail: "Until you unlock it, Clean, Formal, Translate, and your modes work like Light.",
            showPro: showPro,
        )
    }

    static func translator(showPro: @escaping () -> Void) -> ProGateBanner {
        ProGateBanner(
            title: "The translator is part of Waft+",
            detail: "Translate and polish text in any of \(Language.allCases.count) languages with your AI model.",
            showPro: showPro,
        )
    }
}

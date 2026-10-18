import Foundation
import Observation
import WaftCore

@Observable
final class InterfaceLanguageModel {
    let languages: [String]

    var chosen: String? {
        didSet { choiceDidChange() }
    }

    private(set) var needsRelaunch = false

    private let store: any ValueStore<String>
    private let lifecycle: any AppLifecycle
    private let launchedWith: String?

    init(store: any ValueStore<String>, lifecycle: any AppLifecycle) {
        let chosen = store.read()

        self.store = store
        self.lifecycle = lifecycle
        self.chosen = chosen
        launchedWith = chosen
        languages = Bundle.main.localizations
            .filter { $0 != "Base" }
            .sorted { Self.name(of: $0).localizedStandardCompare(Self.name(of: $1)) == .orderedAscending }
    }

    static func name(of identifier: String) -> String {
        let locale = Locale(identifier: identifier)
        guard let name = locale.localizedString(forIdentifier: identifier) else { return identifier }

        return name.sentenceCased(in: locale)
    }

    func relaunch() {
        lifecycle.relaunch()
    }

    private func choiceDidChange() {
        if let chosen {
            store.write(chosen)
        } else {
            store.remove()
        }

        needsRelaunch = chosen != launchedWith
    }
}

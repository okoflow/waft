import Foundation
import Observation
import WaftCore

@Observable
final class APIKeyModel {
    private(set) var isSet: Bool
    var draft = ""

    private let store: any ValueStore<String>

    var canSaveDraft: Bool {
        !draft.isBlank
    }

    init(store: any ValueStore<String>) {
        self.store = store
        isSet = store.exists()
    }

    func saveDraft() {
        guard canSaveDraft, store.write(draft.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }

        draft = ""
        isSet = store.exists()
    }

    func remove() {
        store.remove()
        isSet = store.exists()
    }
}

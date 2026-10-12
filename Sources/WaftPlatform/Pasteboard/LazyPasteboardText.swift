import AppKit
import os

final class LazyPasteboardText: NSObject, NSPasteboardItemDataProvider, Sendable {
    private struct State {
        var isArmed = false
        var wasRead = false
    }

    private let text: String
    private let state = OSAllocatedUnfairLock(initialState: State())

    var wasReadAfterArming: Bool {
        state.withLock { $0.wasRead }
    }

    init(_ text: String) {
        self.text = text
    }

    func arm() {
        state.withLock { $0.isArmed = true }
    }

    func pasteboard(_: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        item.setString(text, forType: type)

        state.withLock { state in
            guard state.isArmed else { return }

            state.wasRead = true
        }
    }
}

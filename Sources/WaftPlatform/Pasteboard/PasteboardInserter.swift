package import WaftCore
import AppKit
import ApplicationServices
import Carbon.HIToolbox
import os

@MainActor
package final class PasteboardInserter: TextInserter {
    private static let readTimeout = Duration.seconds(1.5)
    private static let settleDelay = Duration.milliseconds(150)
    private static let keyReleaseTimeout = Duration.seconds(10)
    private static let idleTimeout = Duration.seconds(2)

    private let focusTracker: any FocusTracker
    private let keyboardState: any KeyboardState
    private var activeInsertions = 0

    package init(focusTracker: any FocusTracker, keyboardState: any KeyboardState) {
        self.focusTracker = focusTracker
        self.keyboardState = keyboardState
    }

    package func insert(_ text: String, into target: FocusTarget, releasing key: PushToTalkKey) async -> InsertionOutcome {
        activeInsertions += 1
        defer { activeInsertions -= 1 }

        let wasReleased = await Poll.until(timeout: Self.keyReleaseTimeout) { !keyboardState.isHeld(key) }
        let current = focusTracker.currentFocus()
        let decision = InsertionDecision.decide(
            isSecureField: isSecureField(current),
            canPostKeys: AXIsProcessTrusted(),
            isFocusOnTarget: target.isSameFocus(as: current),
            isKeyHeld: !wasReleased,
        )

        if case let .skip(reason) = decision {
            Logger.insertion.notice("Skipped pasting: \(reason.rawValue, privacy: .public)")

            return .skipped(reason)
        }

        let prepared = InsertionSpacing.prepared(text, after: current.element?.characterBeforeCaret)
        let outcome = await paste(prepared, releasing: key)
        guard outcome == .pasted else { return outcome }

        Logger.insertion.info("Pasted \(prepared.count) characters into \(current.appDescription, privacy: .public)")

        return .pasted
    }

    package func waitUntilIdle() async {
        await Poll.until(timeout: Self.idleTimeout) { activeInsertions == 0 }
    }

    private func isSecureField(_ focus: FocusTarget) -> Bool {
        guard let element = focus.element else { return IsSecureEventInputEnabled() }

        return element.isSecureTextField
    }

    private func paste(_ text: String, releasing key: PushToTalkKey) async -> InsertionOutcome {
        let snapshot = await Task.detached { PasteboardSnapshot.take() }.value
        let lazyText = LazyPasteboardText(text)
        let item = NSPasteboardItem()
        item.setDataProvider(lazyText, forTypes: [.string])

        let ownChangeCount = NSPasteboard.general.writePrivately(item)

        guard !keyboardState.isHeld(key) else {
            restore(snapshot, expecting: ownChangeCount)

            return .skipped(.keyHeld)
        }

        lazyText.arm()
        PasteShortcut.post()

        guard await Poll.until(timeout: Self.readTimeout, { lazyText.wasReadAfterArming }) else {
            Logger.insertion.notice("Skipped pasting: the app didn't read the text in time")

            return .skipped(.notRead)
        }

        await Task.slept(for: Self.settleDelay)

        restore(snapshot, expecting: ownChangeCount)

        return .pasted
    }

    private func restore(_ snapshot: PasteboardSnapshot, expecting changeCount: Int) {
        switch snapshot.plan {
        case let .skip(reason):
            Logger.insertion.notice("Left the clipboard as it is: \(reason, privacy: .public)")
        case .restore where NSPasteboard.general.changeCount != changeCount:
            Logger.insertion.notice("Left the clipboard as it is: it changed during the paste")
        case .restore:
            snapshot.restore()
        }
    }
}

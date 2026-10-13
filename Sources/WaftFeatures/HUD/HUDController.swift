import Foundation
import Observation
import WaftCore

@Observable
final class HUDController {
    private static let barCount = 9
    private static let levelRefreshInterval: TimeInterval = 0.05

    private(set) var content: HUDContent?
    private(set) var levels = [Float](repeating: 0, count: barCount)

    @ObservationIgnored private var window: (any HUDWindow)?
    @ObservationIgnored private var queuedMessages: [HUDMessage] = []
    @ObservationIgnored private var workingLabel: String?
    @ObservationIgnored private var levelTimer: Timer?
    @ObservationIgnored private var messageTask: Task<Void, Never>?
    @ObservationIgnored private var orderOutTask: Task<Void, Never>?

    private let messageDuration: (HUDMessage) -> Duration
    private let orderOutPause: Duration
    private let makeWindow: (HUDController) -> any HUDWindow

    private var isListening: Bool {
        if case .listening = content {
            true
        } else {
            false
        }
    }

    private var isShowingMessage: Bool {
        if case .message = content {
            true
        } else {
            false
        }
    }

    init(
        messageDuration: @escaping (HUDMessage) -> Duration = \.duration,
        orderOutPause: Duration = .milliseconds(400),
        makeWindow: @escaping (HUDController) -> any HUDWindow = { HUDPanel(rootView: HUDView(hud: $0)) },
    ) {
        self.messageDuration = messageDuration
        self.orderOutPause = orderOutPause
        self.makeWindow = makeWindow
    }

    func showListening(badge: String?, isHandsFree: Bool, level: @escaping @MainActor () -> Float) {
        messageTask?.cancel()
        levels = [Float](repeating: 0, count: Self.barCount)

        present(.listening(badge: badge, isHandsFree: isHandsFree))

        levelTimer?.invalidate()
        levelTimer = .scheduledInCommonModes(every: Self.levelRefreshInterval, repeats: true) { [weak self] in
            self?.pushLevel(level())
        }
    }

    func lockHandsFree() {
        guard case let .listening(badge, _) = content else { return }

        content = .listening(badge: badge, isHandsFree: true)
    }

    func hideListening(handingOverTo label: String? = nil) {
        guard isListening else { return }

        levelTimer?.invalidate()
        levelTimer = nil

        if let label {
            content = .working(label)
        } else {
            hide()
            showNext()
        }
    }

    func setWorking(_ label: String?) {
        workingLabel = label

        showNext()
    }

    func show(_ message: HUDMessage) {
        queuedMessages.append(message)
        showNext()
    }

    func prepareWindow() {
        guard window == nil else { return }

        window = makeWindow(self)
    }

    private func showNext() {
        guard !isListening, !isShowingMessage else { return }

        if !queuedMessages.isEmpty {
            showMessage(queuedMessages.removeFirst())
        } else if let workingLabel {
            present(.working(workingLabel))
        } else {
            hide()
        }
    }

    private func hide() {
        content = nil

        orderOutTask?.cancel()
        orderOutTask = Task { [weak self, orderOutPause] in
            guard await Task.slept(for: orderOutPause), let self, content == nil else { return }

            window?.orderOut(nil)
        }
    }

    private func showMessage(_ message: HUDMessage) {
        present(.message(message))

        messageTask = Task { [weak self, duration = messageDuration(message)] in
            guard await Task.slept(for: duration) else { return }

            self?.messageDidExpire()
        }
    }

    private func messageDidExpire() {
        guard isShowingMessage else { return }

        hide()
        showNext()
    }

    private func present(_ newContent: HUDContent) {
        prepareWindow()
        orderOutTask?.cancel()

        if content == nil {
            window?.showOnActiveScreen()
        }

        content = newContent
    }

    private func pushLevel(_ level: Float) {
        guard let previous = levels.last else { return }

        let rate: Float = level > previous ? 0.7 : 0.3

        levels.removeFirst()
        levels.append(previous + (level - previous) * rate)
    }
}

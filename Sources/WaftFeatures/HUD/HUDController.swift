import Foundation
import Observation
import WaftCore

@Observable
final class HUDController {
    private static let barCount = 9
    private static let levelRefreshInterval: TimeInterval = 0.05

    private(set) var content: HUDContent?
    private(set) var levels = [Float](repeating: 0, count: barCount)
    private(set) var listeningSince = Date.now
    private(set) var hasCopied = false
    private(set) var workingSince = Date.distantPast
    private(set) var stepChangedAt = Date.distantPast

    private var isPointerOver = false

    @ObservationIgnored private var window: (any HUDWindow)?
    @ObservationIgnored private var queuedMessages: [HUDMessage] = []
    @ObservationIgnored private var workingLabel: String?
    @ObservationIgnored private var levelTimer: Timer?
    @ObservationIgnored private var messageTask: Task<Void, Never>?
    @ObservationIgnored private var orderOutTask: Task<Void, Never>?
    @ObservationIgnored private var restingPointer: CGPoint?
    @ObservationIgnored private var pointerHasMoved = false

    private let messageDuration: (HUDMessage) -> Duration
    private let orderOutPause: Duration
    private let copiedPause: Duration
    private let copy: (String) -> Void
    private let makeWindow: (HUDController) -> any HUDWindow

    var canCopyMessage: Bool {
        guard case let .message(message) = content else { return false }

        return message.isCopyable
    }

    var showsCompactMessage: Bool {
        guard canCopyMessage else { return false }

        return !isPointerOver
    }

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
        orderOutPause: Duration = .seconds(1),
        copiedPause: Duration = .milliseconds(1200),
        copy: @escaping (String) -> Void,
        makeWindow: @escaping (HUDController) -> any HUDWindow = { HUDPanel(hud: $0) },
    ) {
        self.messageDuration = messageDuration
        self.orderOutPause = orderOutPause
        self.copiedPause = copiedPause
        self.copy = copy
        self.makeWindow = makeWindow
    }

    func showListening(badge: String, isHandsFree: Bool, level: @escaping @MainActor () -> Float) {
        messageTask?.cancel()

        levels = [Float](repeating: 0, count: Self.barCount)
        listeningSince = .now

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
            noteStep(of: .working(label))
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

    func copyMessage() {
        guard case let .message(message) = content, message.isCopyable else { return }

        copy(message.title)
        hasCopied = true

        expireMessage(after: copiedPause)
    }

    func pointerMoved(to location: CGPoint, isOver: Bool) {
        notePointer(at: location)

        guard pointerHasMoved else {
            setPointerOver(false)

            return
        }

        setPointerOver(isOver)
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
        guard queuedMessages.isEmpty else {
            showMessage(queuedMessages.removeFirst())

            return
        }
        guard let workingLabel else {
            hide()

            return
        }

        present(.working(workingLabel))
    }

    private func hide() {
        content = nil
        isPointerOver = false

        orderOutTask?.cancel()
        orderOutTask = Task { [weak self, orderOutPause] in
            guard await Task.slept(for: orderOutPause), let self, content == nil else { return }

            window?.orderOut(nil)
        }
    }

    private func showMessage(_ message: HUDMessage) {
        hasCopied = false
        isPointerOver = false
        restingPointer = nil
        pointerHasMoved = false
        present(.message(message))

        expireMessage(after: messageDuration(message))
    }

    private func expireMessage(after duration: Duration) {
        messageTask?.cancel()
        messageTask = Task { [weak self] in
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

        noteStep(of: newContent)
        content = newContent
    }

    private func notePointer(at location: CGPoint) {
        guard let restingPointer else {
            restingPointer = location

            return
        }
        guard location != restingPointer else { return }

        pointerHasMoved = true
    }

    private func setPointerOver(_ isOver: Bool) {
        guard isOver != isPointerOver else { return }

        isPointerOver = isOver

        guard canCopyMessage else { return }
        guard isOver else {
            expireMessage(after: copiedPause)

            return
        }

        messageTask?.cancel()
    }

    private func noteStep(of newContent: HUDContent) {
        guard case let .working(label) = newContent else { return }
        guard case let .working(current) = content else {
            workingSince = .now

            return
        }
        guard label != current else { return }

        stepChangedAt = .now
    }

    private func pushLevel(_ level: Float) {
        guard let previous = levels.last else { return }

        let rate: Float = level > previous ? 0.7 : 0.3

        levels.removeFirst()
        levels.append(previous + (level - previous) * rate)
    }
}

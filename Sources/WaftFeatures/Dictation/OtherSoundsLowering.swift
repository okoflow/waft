import WaftCore

final class OtherSoundsLowering {
    private let outputVolume: any OutputVolume
    private let delay: Duration
    private var task: Task<Void, Never>?

    init(outputVolume: any OutputVolume, delay: Duration = .milliseconds(250)) {
        self.outputVolume = outputVolume
        self.delay = delay
    }

    func lower(while isWanted: @escaping () -> Bool) {
        task?.cancel()
        task = Task { [weak self, delay] in
            guard await Task.slept(for: delay), let self, isWanted() else { return }

            outputVolume.lower(to: 0.5)
        }
    }

    func restore() {
        task?.cancel()
        task = nil

        outputVolume.restore()
    }
}
